import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Set minimum window size: 1166x877 (left 256 + middle 400 + right flexible)
    self.setFrame(NSRect(x: windowFrame.origin.x, y: windowFrame.origin.y, width: 1166, height: 877), display: true)
    self.minSize = NSSize(width: 1166, height: 877)
    self.maxSize = NSSize(width: 9999, height: 9999)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
