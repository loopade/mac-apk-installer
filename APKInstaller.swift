import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow!
    var status: NSTextField!
    var detail: NSTextField!
    var spinner: NSProgressIndicator!
    var pendingAPK: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        let rect = NSRect(x: 0, y: 0, width: 460, height: 170)
        window = NSWindow(contentRect: rect, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "APK 安装器"
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.level = .floating

        let view = NSView(frame: rect)
        status = NSTextField(labelWithString: "等待 APK…")
        status.font = .boldSystemFont(ofSize: 16)
        status.frame = NSRect(x: 28, y: 112, width: 404, height: 24)
        detail = NSTextField(labelWithString: "双击 APK 后会自动安装到已连接的手机")
        detail.textColor = .secondaryLabelColor
        detail.frame = NSRect(x: 28, y: 78, width: 404, height: 22)
        spinner = NSProgressIndicator(frame: NSRect(x: 28, y: 38, width: 404, height: 20))
        spinner.style = .bar
        spinner.isIndeterminate = true
        spinner.isHidden = true
        view.addSubview(status); view.addSubview(detail); view.addSubview(spinner)
        window.contentView = view
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        if let apk = pendingAPK {
            pendingAPK = nil
            install(apk: apk)
        }
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.terminate(nil)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let apk = urls.first else { return }
        if window == nil {
            pendingAPK = apk.path
            return
        }
        install(apk: apk.path)
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        guard let apk = filenames.first else { return }
        if window == nil {
            pendingAPK = apk
            return
        }
        install(apk: apk)
    }

    func install(apk: String) {
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        let name = URL(fileURLWithPath: apk).lastPathComponent
        status.stringValue = "正在安装…"
        detail.stringValue = name
        spinner.isHidden = false
        spinner.startAnimation(nil)
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/adb")
        if !FileManager.default.isExecutableFile(atPath: task.executableURL!.path) {
            task.executableURL = URL(fileURLWithPath: "/usr/local/bin/adb")
        }
        task.arguments = ["install", "-r", "-d", "-t", apk]
        let pipe = Pipe()
        task.standardOutput = pipe; task.standardError = pipe
        DispatchQueue.global().async {
            do {
                try task.run(); task.waitUntilExit()
                let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                DispatchQueue.main.async {
                    self.spinner.stopAnimation(nil); self.spinner.isHidden = true
                    if task.terminationStatus == 0 && output.contains("Success") {
                        self.status.stringValue = "安装成功"
                        self.detail.stringValue = name
                    } else {
                        self.status.stringValue = "安装失败"
                        self.detail.stringValue = output.trimmingCharacters(in: .whitespacesAndNewlines).suffix(180).description
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.spinner.stopAnimation(nil); self.spinner.isHidden = true
                    self.status.stringValue = "安装失败"
                    self.detail.stringValue = error.localizedDescription
                }
            }
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()