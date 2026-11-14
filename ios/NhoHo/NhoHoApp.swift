import SwiftUI
import WebKit
#if !FREE_PERSONAL_BUILD
import WidgetKit
#endif

@main struct NhoHoApp: App {
    @AppStorage("journalOrigin") private var origin = Bundle.main.object(forInfoDictionaryKey: "NhoHoDefaultOrigin") as? String ?? ""
    @State private var input = ""
    @State private var error = ""
    @State private var showSettings = false
    @State private var loadError: String?
    @State private var reloadID = UUID()
    var body: some Scene {
        WindowGroup {
            if let url = URL(string: origin), url.scheme == "https", url.host != nil {
                VStack(spacing: 0) {
                    HStack {
                        Text("Nhớ Hộ").font(.headline)
                        Spacer()
                        Button("Kết nối", systemImage: "network") { input = origin; showSettings = true }
                    }.padding(.horizontal).padding(.vertical, 8)
                    if let loadError {
                        VStack(spacing: 10) {
                            Text(loadError).font(.footnote)
                            Button("Thử tải lại") { self.loadError = nil; reloadID = UUID() }
                        }.padding().frame(maxWidth: .infinity).background(Color.yellow.opacity(0.15))
                    }
                    JournalWebView(origin: url, loadError: $loadError).id(origin + reloadID.uuidString)
                }
                .ignoresSafeArea(.container, edges: .bottom)
                .sheet(isPresented: $showSettings) {
                    NavigationStack {
                        Form {
                            Section("Địa chỉ ứng dụng") {
                                TextField("https://…", text: $input).textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                                Text("Đổi địa chỉ sẽ mở kho dữ liệu khác. Xuất bản sao lưu trước nếu cần chuyển nhật ký.").font(.footnote)
                            }
                            Button("Kết nối") { connect() }
                            Text(error).foregroundStyle(.red)
                        }.navigationTitle("Kết nối Nhớ Hộ")
                            .toolbar { Button("Đóng") { showSettings = false } }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    Image(systemName: "book.closed.fill").font(.largeTitle).foregroundStyle(.green)
                    Text("Một chút hôm nay.").font(.largeTitle.bold())
                    Text("Nhập địa chỉ HTTPS của Nhớ Hộ đã triển khai để mở lịch và nhật ký trong ứng dụng.")
                    TextField("https://…", text: $input).textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL).textFieldStyle(.roundedBorder)
                    Button("Mở nhật ký") {
                        connect()
                    }.buttonStyle(.borderedProminent)
                    Text(error).foregroundStyle(.red)
                    Text("Dữ liệu Safari/PWA không tự chuyển sang ứng dụng. Xuất rồi nhập bản sao lưu trong Cài đặt để mang nhật ký sang đây.").font(.footnote).foregroundStyle(.secondary)
                }.padding(28)
            }
        }
    }
    private func connect() {
        guard let u = URL(string: input.trimmingCharacters(in: .whitespacesAndNewlines)), u.scheme == "https", let host = u.host, !host.isEmpty, u.user == nil, u.password == nil, u.port == nil,
              (u.path.isEmpty || u.path == "/"), u.query == nil, u.fragment == nil else { error = "Nhập địa chỉ gốc HTTPS, không kèm đường dẫn."; return }
        origin = "https://" + host
        loadError = nil
        error = ""
        showSettings = false
    }
}
struct JournalWebView: UIViewRepresentable {
    let origin: URL
    @Binding var loadError: String?
    func makeCoordinator() -> Coordinator { Coordinator(origin: origin, loadError: $loadError) }
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        #if !FREE_PERSONAL_BUILD
        config.userContentController.add(context.coordinator, name: "journalWidget")
        #endif
        config.userContentController.add(context.coordinator, name: "journalExport")
        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        web.uiDelegate = context.coordinator
        web.isOpaque = false
        web.backgroundColor = UIColor(red: 0.965, green: 0.969, blue: 0.949, alpha: 1)
        web.load(URLRequest(url: origin.appendingPathComponent("/").appending(queryItems: [URLQueryItem(name: "view", value: "home")])))
        return web
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        #if !FREE_PERSONAL_BUILD
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "journalWidget")
        #endif
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "journalExport")
    }
    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
        let origin: URL
        @Binding var loadError: String?
        init(origin: URL, loadError: Binding<String?>) { self.origin = origin; self._loadError = loadError }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { loadError = nil }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            if (error as NSError).code != NSURLErrorCancelled { loadError = "Chưa mở được Nhớ Hộ. Kiểm tra mạng hoặc địa chỉ trong Kết nối." }
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            if (error as NSError).code != NSURLErrorCancelled { loadError = "Trang bị gián đoạn. Bạn có thể thử tải lại." }
        }
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.frameInfo.isMainFrame, message.frameInfo.securityOrigin.protocol == "https", message.frameInfo.securityOrigin.host == origin.host,
                  let body = message.body as? [String: Any] else { return }
            if message.name == "journalExport" {
                guard let text = body["text"] as? String, text.utf8.count <= 20 * 1024 * 1024,
                      let name = body["name"] as? String, name == (name as NSString).lastPathComponent,
                      ["json", "ics"].contains((name as NSString).pathExtension),
                      let web = message.webView, let controller = web.window?.rootViewController else { return }
                do {
                    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                    let file = folder.appendingPathComponent(name)
                    try Data(text.utf8).write(to: file, options: .atomic)
                    let share = UIActivityViewController(activityItems: [file], applicationActivities: nil)
                    share.popoverPresentationController?.sourceView = web
                    share.popoverPresentationController?.sourceRect = CGRect(x: web.bounds.midX, y: web.bounds.midY, width: 1, height: 1)
                    share.completionWithItemsHandler = { _, _, _, _ in try? FileManager.default.removeItem(at: folder) }
                    controller.present(share, animated: true)
                } catch { }
                return
            }
            #if !FREE_PERSONAL_BUILD
            do {
                if body["clear"] as? Bool == true { try JournalWidgetStore.save(.empty) }
                else {
                    let data = try JSONSerialization.data(withJSONObject: body)
                    guard data.count <= 300_000 else { return }
                    let value = try JSONDecoder().decode(JournalSnapshot.self, from: data)
                    guard value.text.count <= 4000, value.photo == nil || value.image != nil else { return }
                    try JournalWidgetStore.save(value)
                }
                WidgetCenter.shared.reloadTimelines(ofKind: "NhoHoMemory")
            } catch { /* Keep the last successfully written widget snapshot. */ }
            #endif
        }
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
            if url.scheme == "https" && url.host == origin.host { decisionHandler(.allow) }
            else { decisionHandler(.cancel) }
        }
        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            let alert = UIAlertController(title: "Nhớ Hộ", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Để sau", style: .cancel) { _ in completionHandler(false) })
            alert.addAction(UIAlertAction(title: "Đồng ý", style: .default) { _ in completionHandler(true) })
            guard let controller = webView.window?.rootViewController else { completionHandler(false); return }
            controller.present(alert, animated: true)
        }
    }
}
