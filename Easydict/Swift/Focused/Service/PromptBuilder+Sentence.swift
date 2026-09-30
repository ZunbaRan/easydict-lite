// Retained from Easydict StreamService+Prompt.swift. Copyright © 2024 izual. GPL-3.0.

import Foundation

extension PromptBuilder {
    func sentenceMessages(_ chatQuery: ChatQueryParam) -> [ChatMessage] {
        let (sentence, sourceLanguage, targetLanguage, _, enableSystemPrompt) = chatQuery.unpack()

        
        var prompt = ""
        var keyWords = "Key Words"
        var grammarParse = "Grammar Parsing"
        var literalTranslation = "Literal Translation"
        var freeTranslation = "Free Translation"

        if answerLanguage.isChinese {
            keyWords = "重点词汇"
            grammarParse = "语法分析"
            literalTranslation = "直译"
            freeTranslation = "意译"
        }

        let sourceLanguageString = sourceLanguage.rawValue
        let targetLanguageString = targetLanguage.rawValue

        let sentencePrompt =
            "Here is a \(sourceLanguageString) sentence: \"\"\"\(sentence)\"\"\".\n"
        prompt += sentencePrompt

        let directTranslationPrompt =
            "First, translate the sentence into \(targetLanguageString) literally, keeping the original format and including all information. Use the format: \"\(literalTranslation):\n{literal_translation}\".\n\n"
        prompt += directTranslationPrompt

        let stepByStepPrompt = "Then, follow these steps:\n"
        prompt += stepByStepPrompt

        let keyWordsPrompt =
            "1. List up to 5 key words, phrases, or collocations from the sentence. For each, include all parts of speech and meanings, and specify its meaning in this context if it differs from the common meaning. Use the format: \"\(keyWords):\n{key_words_pos}\".\n\n"
        prompt += keyWordsPrompt

        let grammarParsePrompt =
            "2. Analyze the grammatical structure of the sentence. Use the format: \"\(grammarParse):\n{grammatical_analysis}\".\n\n"
        prompt += grammarParsePrompt

        let freeTranslationPrompt =
            "3. Identify any issues in the literal translation, such as non-standard \(targetLanguageString) expressions, awkwardness, or ambiguity. Provide a free translation that maintains the original meaning but is clearer and more natural in \(targetLanguageString). If the sentence includes idioms, metaphors, historical references, or famous works, provide a detailed introduction after the translation. Use the format: \"\(freeTranslation):\n{free_translation}\".\n\n"
        prompt += freeTranslationPrompt

        let answerLanguagePrompt = "Answer in \(answerLanguage.rawValue).\n"
        prompt += answerLanguagePrompt

        let disableNotePrompt =
            "Total word count should not exceed 1000. Do not include additional information or notes."
        prompt += disableNotePrompt

        // Add few-shot examples or other messages as needed
        let chineseFewShot = [
            chatMessagePair(
                userContent: """
                Here is an English sentence: \"\"\"But whether the incoming chancellor will offer dynamic leadership, rather than more of Germany’s recent drift, is hard to say.\"\"\"
                First, provide the Simplified Chinese translation of this sentence.
                Then, follow these steps:
                1. List the key vocabulary and phrases in the sentence. Include all parts of speech and meanings, and explain their specific meanings in this context.
                2. Analyze the grammatical structure of the sentence.
                3. Provide the inferred translation in Simplified Chinese.
                Answer in Simplified Chinese.
                """,
                assistantContent: """
                直译：
                但是这位新任总理是否能够提供有活力的领导，而不是延续德国最近的漂泊，还很难说。

                重点词汇：
                incoming: adj. 正来临的；新任的。
                chancellor: n. 总理；大臣。这里指德国总理。
                dynamic: adj. 有活力的；动态的。
                dynamic leadership: 强力的领导。
                drift: n. 漂流；漂泊。可以理解为随波逐流，和前面的 dynamic 做对比。

                语法分析：
                该句子为一个复合句。主句为 "But...is hard to say."（但是这位新任总理是否能提供强力的领导还难以说），其中包含了一个 whether 引导的从句作宾语从句。

                意译：
                但是这位新任总理是否能够提供强力的领导，而不是继续德国最近的随波逐流之势，还很难说。
                """
            ),

            chatMessagePair(
                userContent: "The Sword of Damocles",
                assistantContent: """
                直译：
                达摩克利斯之剑

                重点词汇：
                Sword: n. 剑。
                Damocles: n. 达摩克利斯，一个古希腊传说中的人物。

                语法分析：
                这是一个简单名词短语。

                意译：
                达摩克利斯之剑

                （达摩克利斯之剑，又称为“悬顶之剑”，源自古希腊的一个寓言故事。这个短语经常被用来描述那些处于高位但随时可能遭遇不幸或灾难的人的处境。它提醒人们，权力和成功往往伴随着风险和挑战。）
                """
            ),

            chatMessagePair(
                userContent: "better late than never",
                assistantContent: """
                直译：
                迟到总比不到好

                重点词汇：
                better: adj. 较好的；更好的。
                late: adj. 迟到的；晚的。
                never: adv. 从来不；从不。

                语法分析：
                这是一个固定短语。

                意译：
                迟做总比不做好

                （这是一句广为人知的英语谚语，传达了一个乐观且鼓励的态度，即在面对任务、决定或目标时，即使开始得较晚或者错过了最初的机会，采取行动并最终完成仍然比完全放弃要好。它强调了坚持与努力的价值，即便成果来得晚些，也不失为一种成功。）
                """
            ),

            chatMessagePair(
                userContent: "Ukraine may get another Patriot battery.",
                assistantContent: """
                直译：
                乌克兰可能会获得另一套爱国者导弹系统。

                重点词汇：
                Ukraine: n. 乌克兰，一个东欧的共和制国家。
                Patriot: n. 爱国者。这里指爱国者导弹系统。
                battery: n. 电池；炮兵连。这里指导弹炮组。

                语法分析：
                该句为简单句。主语为 "Ukraine"，谓语为 "may get"，宾语为 "another Patriot battery"。

                意译：
                乌克兰可能会获得另一套爱国者导弹系统。
                """
            ),
        ].flatMap { $0 }

        let englishFewShot = [
            chatMessagePair(
                userContent: """
                Here is an English sentence: \"\"\"But whether the incoming chancellor will offer dynamic leadership, rather than more of Germany’s recent drift, is hard to say.\"\"\"

                First, translate the sentence into English literally, keeping the original format and including all information. Use the following format: \"Literal Translation:\n{literal_translation_result}\".

                Then, follow these steps:

                1. List up to 5 key words, common phrases, or collocations in the sentence. For each, include all parts of speech and meanings, and explain its specific meaning in this context. Use the format: \"Key Words:\n{key_words}\".

                2. Analyze the grammatical structure of the sentence. Use the format: \"Grammar Parsing:\n{grammatical_analysis}\".

                3. Provide a free translation of the sentence, ensuring it retains the original meaning but is easier to understand and more natural in English. Keep the original format unchanged. Use the format: \"Free Translation:\n{free_translation_result}\".

                Answer in English.
                """,
                assistantContent: """
                Literal Translation:
                But whether the incoming chancellor will offer dynamic leadership, rather than more of Germany’s recent drift, is difficult to say.

                Key Words:
                chancellor: n. Chancellor; minister. Here it refers to the German chancellor.
                dynamic: adj. energetic; dynamic. Here it refers to strong leadership.
                drift: n. To drift; to drift. Here it means to go with the flow, in contrast to the previous dynamic.

                Grammar Parsing:
                The sentence is a complex sentence. The main clause is "But .... is hard to say" (But it is hard to say whether the new prime minister can provide strong leadership), which contains a whether clause as the object clause.

                Free Translation:
                It's hard to say whether the incoming chancellor will offer dynamic leadership, or just prolong Germany's recent drift.
                """
            ),
        ].flatMap { $0 }

        var messages: [ChatMessage] =
            enableSystemPrompt
                ? [ChatMessage(role: .system, content: PromptBuilder.sentenceSystemPrompt)] : []

        if answerLanguage.isChinese {
            messages += chineseFewShot
        } else {
            messages += englishFewShot
        }

        let userMessage: ChatMessage = .init(role: .user, content: prompt)
        messages.append(userMessage)

        return messages
    }

}
