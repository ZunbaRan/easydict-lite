#!/usr/bin/env python3
"""Generate the small Xcode build graph from the focused fork's explicit source files."""

from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[2]
objects = {}


def identifier(name):
    return hashlib.sha1(name.encode()).hexdigest()[:24].upper()


def add(label, isa, **fields):
    key = identifier(label)
    objects[key] = {"isa": isa, **fields}
    return key


def render(value):
    if isinstance(value, dict):
        return "{ " + " ".join(f"{json.dumps(k)} = {render(v)};" for k, v in value.items()) + " }"
    if isinstance(value, list):
        return "(" + ", ".join(render(v) for v in value) + ")"
    return json.dumps(str(value))


def file_reference(path, file_type):
    return add(str(path), "PBXFileReference", lastKnownFileType=file_type, path=str(path), sourceTree="SOURCE_ROOT")


def build_file(reference):
    return add("build:" + reference, "PBXBuildFile", fileRef=reference)


sources = [file_reference(path, "sourcecode.swift") for path in sorted(Path("Easydict/Swift/Focused").rglob("*.swift"))]
tests = [file_reference(Path(path), "sourcecode.swift") for path in [
    "EasydictTests/Support/TestSuites.swift",
    "EasydictTests/Utility/ThrottleGateTests.swift",
    "EasydictTests/Service/OpenAI/OpenAIStreamTaskControlTests.swift",
]]
resources = [file_reference(Path(path), kind) for path, kind in [
    ("Easydict/App/Localizable.xcstrings", "text.json.xcstrings"),
    ("Easydict/App/InfoPlist.xcstrings", "text.json.xcstrings"),
    ("Easydict/App/AppIcon.icns", "image.icns"),
]]
app_product = add("app-product", "PBXFileReference", explicitFileType="wrapper.application", path="easydict-lite.app", sourceTree="BUILT_PRODUCTS_DIR")
test_product = add("test-product", "PBXFileReference", explicitFileType="wrapper.cfbundle", path="EasydictTests.xctest", sourceTree="BUILT_PRODUCTS_DIR")
packages, products, links = [], [], []
for name, url, version in [
    ("Alamofire", "https://github.com/Alamofire/Alamofire.git", "5.12.2"),
    ("Defaults", "https://github.com/sindresorhus/Defaults.git", "8.2.0"),
    ("SFSafeSymbols", "https://github.com/SFSafeSymbols/SFSafeSymbols.git", "5.3.0"),
]:
    package = add("package:" + name, "XCRemoteSwiftPackageReference", repositoryURL=url, requirement={"kind": "exactVersion", "version": version})
    product = add("package-product:" + name, "XCSwiftPackageProductDependency", package=package, productName=name)
    packages.append(package)
    products.append(product)
    links.append(add("link:" + name, "PBXBuildFile", productRef=product))

app_sources = add("app-sources", "PBXSourcesBuildPhase", buildActionMask="2147483647", files=[build_file(ref) for ref in sources], runOnlyForDeploymentPostprocessing="0")
test_sources = add("test-sources", "PBXSourcesBuildPhase", buildActionMask="2147483647", files=[build_file(ref) for ref in tests], runOnlyForDeploymentPostprocessing="0")
app_resources = add("app-resources", "PBXResourcesBuildPhase", buildActionMask="2147483647", files=[build_file(ref) for ref in resources], runOnlyForDeploymentPostprocessing="0")
frameworks = add("app-frameworks", "PBXFrameworksBuildPhase", buildActionMask="2147483647", files=links, runOnlyForDeploymentPostprocessing="0")
project_id = identifier("project")
app_id = identifier("app-target")
proxy = add("test-proxy", "PBXContainerItemProxy", containerPortal=project_id, proxyType="1", remoteGlobalIDString=app_id, remoteInfo="Easydict")
dependency = add("test-dependency", "PBXTargetDependency", target=app_id, targetProxy=proxy)


def configurations(scope, extra):
    entries = []
    for name in ["Debug", "Release"]:
        settings = {
            "MACOSX_DEPLOYMENT_TARGET": "26.0", "SDKROOT": "macosx", "SWIFT_VERSION": "5.0",
            "SWIFT_OPTIMIZATION_LEVEL": "-Onone" if name == "Debug" else "-O",
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG" if name == "Debug" else "",
            "ENABLE_TESTABILITY": "YES" if name == "Debug" else "NO",
            "CODE_SIGN_STYLE": "Automatic", "CLANG_ENABLE_MODULES": "YES", **extra,
        }
        entries.append(add(scope + name, "XCBuildConfiguration", name=name, buildSettings=settings))
    return add(scope + "-config-list", "XCConfigurationList", buildConfigurations=entries, defaultConfigurationIsVisible="0", defaultConfigurationName="Release")


app_config = configurations("app", {
    "PRODUCT_NAME": "easydict-lite", "PRODUCT_MODULE_NAME": "Easydict", "EXECUTABLE_NAME": "easydict-lite",
    "PRODUCT_BUNDLE_IDENTIFIER": "org.easydict.focused", "INFOPLIST_FILE": "Easydict/App/Info.plist",
    "GENERATE_INFOPLIST_FILE": "NO", "ENABLE_APP_SANDBOX": "NO", "SWIFT_EMIT_LOC_STRINGS": "NO",
    "COMBINE_HIDPI_IMAGES": "YES",
})
test_config = configurations("tests", {
    "PRODUCT_NAME": "EasydictTests", "PRODUCT_BUNDLE_IDENTIFIER": "org.easydict.focused.tests",
    "GENERATE_INFOPLIST_FILE": "YES", "BUNDLE_LOADER": "$(TEST_HOST)",
    "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/easydict-lite.app/Contents/MacOS/easydict-lite",
})
add("app-target", "PBXNativeTarget", name="Easydict", productName="easydict-lite", productReference=app_product,
    productType="com.apple.product-type.application", buildConfigurationList=app_config,
    buildPhases=[app_sources, frameworks, app_resources], dependencies=[], buildRules=[], packageProductDependencies=products)
test_id = add("test-target", "PBXNativeTarget", name="EasydictTests", productName="EasydictTests", productReference=test_product,
    productType="com.apple.product-type.bundle.unit-test", buildConfigurationList=test_config,
    buildPhases=[test_sources], dependencies=[dependency], buildRules=[])
products_group = add("products", "PBXGroup", name="Products", children=[app_product, test_product], sourceTree="<group>")
source_group = add("source-group", "PBXGroup", name="Focused App", children=sources, sourceTree="<group>")
test_group = add("test-group", "PBXGroup", name="Retained Tests", children=tests, sourceTree="<group>")
resource_group = add("resource-group", "PBXGroup", name="Resources", children=resources, sourceTree="<group>")
main_group = add("main-group", "PBXGroup", children=[source_group, test_group, resource_group, products_group], sourceTree="<group>")
add("project", "PBXProject", attributes={"LastUpgradeCheck": "2600"}, buildConfigurationList=configurations("project", {}),
    compatibilityVersion="Xcode 14.0", developmentRegion="en", knownRegions=["en", "zh-Hans", "Base"],
    mainGroup=main_group, productRefGroup=products_group, projectDirPath="", projectRoot="", targets=[app_id, test_id], packageReferences=packages)
project = ROOT / "Easydict.xcodeproj"
(project / "project.pbxproj").write_text("// !$*UTF8*$!\n" + render({"archiveVersion": "1", "classes": {}, "objectVersion": "56", "objects": objects, "rootObject": project_id}) + "\n")
scheme_dir = project / "xcshareddata/xcschemes"
scheme_dir.mkdir(parents=True, exist_ok=True)


def reference(key, name, product):
    return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{key}" BuildableName="{product}" BlueprintName="{name}" ReferencedContainer="container:Easydict.xcodeproj"/>'


app_ref = reference(app_id, "Easydict", "easydict-lite.app")
test_ref = reference(test_id, "EasydictTests", "EasydictTests.xctest")
(scheme_dir / "Easydict.xcscheme").write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>
<BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{app_ref}</BuildActionEntry>
</BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{test_ref}</TestableReference></Testables></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{app_ref}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO"><BuildableProductRunnable runnableDebuggingMode="0">{app_ref}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
''')
