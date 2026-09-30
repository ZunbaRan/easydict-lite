// Retained from Easydict StreamService+Prompt.swift. Copyright © 2024 izual. GPL-3.0.

import Foundation

extension PromptBuilder {
    func dictMessages(_ chatQuery: ChatQueryParam) -> [ChatMessage] {
        let (word, sourceLanguage, targetLanguage, _, enableSystemPrompt) = chatQuery.unpack()

        var prompt = ""


        var pronunciation = "Pronunciation"
        var tense = "Tense"
        var translationTitle = "Translation"
        var explanation = "Explanation"
        var etymology = "Etymology"
        var howToRemember = "How to remember"
        var cognate = "Cognate"
        var synonym = "Synonym"
        var antonym = "Antonym"
        var commonPhrases = "common Phrases"
        var exampleSentence = "Example sentence"

        let isEnglishWord = sourceLanguage == .english && word.isEnglishWord
        let isEnglishPhrase = sourceLanguage == .english && word.isEnglishPhrase

        let isChineseWord =
            sourceLanguage.isChinese && word.isChineseWord

        let isWord = isEnglishWord || isChineseWord

        let sourceLanguageString = sourceLanguage.rawValue

        let answerLanguagePrompt = "Using \(answerLanguage.rawValue): \n"
        prompt.append(answerLanguagePrompt)

        let queryWordPrompt = "Here is a \(sourceLanguageString) word: \"\"\"\(word)\"\"\", "
        prompt.append(queryWordPrompt)

        if answerLanguage.isChinese {
            pronunciation = "发音"
            tense = "时态"
            translationTitle = "翻译"
            explanation = "解释"
            etymology = "词源学"
            howToRemember = "记忆方法"
            cognate = "同根词"
            synonym = "近义词"
            antonym = "反义词"
            commonPhrases = "常用短语"
            exampleSentence = "例句"
        }

        let pronunciationPrompt =
            "Look up its pronunciation, use the format: \"\(pronunciation): /{pronunciation}/\" \n"
        prompt.append(pronunciationPrompt)

        if isEnglishWord {
            let partOfSpeechAndMeaningPrompt = """
            Look up all parts of speech and meanings. Use the format: "{pos}. {meaning}", with one part of speech and meaning per line.
            """
            prompt.append(partOfSpeechAndMeaningPrompt)

            let tensePrompt = """
            Look up all tenses of the word based on its part of speech. If the word is a noun, provide only its plural form. If the word is a verb, provide its third person singular, present participle, past tense, and past participle forms. Show only one tense per line, use the format: "\(
                tense
            ):\n{tenses}".
            """
            prompt.append(tensePrompt)
        } else {
            let translationPrompt = translationPrompt(
                text: word, from: sourceLanguage, to: targetLanguage
            )
            prompt.append(
                "\(translationPrompt), use the format: \"\(translationTitle): {translation}\" "
            )
        }

        let explanationPrompt = """
        Look up its brief explanation in \(
            answerLanguage
                .rawValue
        ) in a clear and understandable way. Use the format: "\(explanation): {brief_explanation}"
        """
        prompt.append(explanationPrompt)

        let etymologyPrompt = """
        Look up its detailed etymology, including the original origin, changes in meaning, and current common meaning. Use the format: "\(
            etymology
        ): {detailed_etymology}".
        """
        prompt.append(etymologyPrompt)

        if isEnglishWord {
            let rememberWordPrompt = """
            Provide some efficient memory techniques and tips to better remember this word, such as association and decomposition, etc. Use the format: "\(
                howToRemember
            ): {how_to_remember}".
            """
            prompt.append(rememberWordPrompt)

            let cognatesPrompt = """
            Look up main \(
                sourceLanguageString
            ) words with the same root. List no more than 4, excluding phrases. Display all parts of speech and meanings. If there are words with the same root, use the format: "\(
                cognate
            ): {cognates}", otherwise don't display it.
            """
            prompt.append(cognatesPrompt)
        }

        if isWord || isEnglishPhrase {
            let synonymsPrompt = """
            Look up main \(sourceLanguageString) synonyms, no more than 3. If there are synonyms, use the format: "\(
                synonym
            ): {synonyms}".
            """
            prompt.append(synonymsPrompt)

            let antonymsPrompt = """
            Look up main \(sourceLanguageString) antonyms, no more than 3. If there are antonyms, use the format: "\(
                antonym
            ): {antonyms}".
            """
            prompt.append(antonymsPrompt)

            let phrasePrompt = """
            Look up main \(sourceLanguageString) phrases, no more than 3. If there are phrases, use the format: "\(
                commonPhrases
            ): {phrases}".
            """
            prompt.append(phrasePrompt)
        }

        let exampleSentencePrompt = """
        Look up main \(
            sourceLanguageString
        ) example sentences and their translations, no more than 2. Mark the specific meaning in the translated sentence with *. Use the format: "\(
            exampleSentence
        ):\n{example_sentences}".
        """
        prompt.append(exampleSentencePrompt)

        let wordCountPrompt = """
        Ensure the explanation is around 50 words and the etymology is between 100 and 400 words. Total word count should not exceed 1000. Word count does not need to be displayed.
        """
        prompt.append(wordCountPrompt)

        let disableNotePrompt = "Do not display additional information or notes."
        prompt.append(disableNotePrompt)

        let chineseFewShot: [ChatMessage] = [
            chatMessagePair(
                userContent: """
                Using Simplified-Chinese:
                Here is a English word: \"\"\"album\"\"\",
                Look up its pronunciation, part of speech and meanings, tenses, explanation, etymology, how to remember, cognates, synonyms, antonyms, phrases, example sentences.
                """,
                assistantContent: """
                发音：/ ˈælbəm /

                n. 相册；唱片集；集邮簿

                时态：
                复数：albums

                解释：{explanation}

                词源学：早期 17 世纪：源自拉丁语“albus”（意即“白色”）的中性单词“album”，原意为“白板”。该词是从拉丁语短语“album amicorum”（意即“好友相册”，一种可收集亲笔签名、素描、诗句等内容的空白书籍）中借来的，最初被有意作为拉丁语词汇使用。

                记忆方法：{how_to_remember}

                同根词：
                n. almanac 年历，历书
                n. anthology 选集，文选

                近义词：record, collection, compilation
                反义词：dispersal, disarray, disorder

                常用短语：
                1. White Album: 白色相簿
                2. photo album: 写真集；相册；相簿
                3. debut album: 首张专辑

                例句：
                1. Their new album is dynamite.
                （他们的*新唱*引起轰动。）
                2. I stuck the photos into an album.
                （我把照片贴到*相册*上。）
                """
            ),

            chatMessagePair(
                userContent: "raven",
                assistantContent: """
                发音：/ ˈreɪvən /

                n. 掠夺，劫掠；大乌鸦
                adj. 乌黑的
                vt. 掠夺；狼吞虎咽
                vi. 掠夺；狼吞虎咽

                时态：
                复数：ravens
                第三人称单数：ravens
                现在分词：ravening
                过去式：ravened
                过去分词：ravened

                解释：{explanation}

                词源学：{etymology}

                记忆方法：{how_to_remember}

                同根词：
                n. ravage 蹂躏，破坏
                vi. ravage 毁坏；掠夺
                vt. ravage 毁坏；破坏；掠夺
                adj. ravenous 贪婪的；渴望的；狼吞虎咽的

                近义词：seize, blackbird
                反义词：protect, guard, defend

                常用短语：
                1. Raven paradox: 乌鸦悖论
                2. raven hair: 乌黑的头发
                3. The Raven: 乌鸦；魔鸟

                例句：
                1. She has long raven hair.
                （她有一头*乌黑的*长头发。）
                2. The raven is often associated with death and the supernatural.
                （*乌鸦*常常与死亡和超自然现象联系在一起。）
                """
            ),

            chatMessagePair(
                userContent: "js",
                assistantContent: """
                Pronunciation: {Pronunciation}

                n. JavaScript 的缩写，一种直译式脚本语言。

                Explanation: {Explanation}

                Etymology: {Etymology}

                Synonym: {Synonym}

                Phrases: {Phrases}

                Example Sentences: {Example_Sentences}
                """
            ),
        ].flatMap { $0 }

        let englishFewShot: [ChatMessage] = [
            chatMessagePair(
                userContent: """
                Using English:
                Here is a English word: "raven",
                Look up its pronunciation, part of speech and meanings, tenses, explanation, etymology, how to remember, cognates, synonyms, antonyms, phrases, example sentences.
                """,
                assistantContent: """
                Pronunciation: / ˈreɪvən /

                n. A large, black bird with a deep croak
                v. To seize or devour greedily

                Tense:
                Plural: ravens
                Present participle: ravening
                Past tense: ravened

                Explanation: xxx

                Etymology: xxx

                How to remember: xxx

                Cognates: xxx

                Synonyms: xxx
                Antonyms: xxx

                Phrases: xxx

                Example Sentences: xxx
                """
            ),

            chatMessagePair(
                userContent: "acg",
                assistantContent: """
                Pronunciation: xxx

                n. acg: Animation, Comic, Game

                Explanation: xxx

                Etymology: xxx

                How to remember: xxx

                Cognates: xxx

                Synonyms: xxx
                Antonyms: xxx

                Phrases: xxx

                Example Sentences: xxx
                """
            ),
        ].flatMap { $0 }

        var messages: [ChatMessage] =
            enableSystemPrompt
                ? [ChatMessage(role: .system, content: PromptBuilder.dictSystemPrompt)]
                : []

        if answerLanguage.isChinese {
            messages += chineseFewShot
        } else {
            messages += englishFewShot
        }

        let userMessage: ChatMessage = .init(role: .user, content: prompt)
        messages.append(userMessage)

        return messages
    }}
