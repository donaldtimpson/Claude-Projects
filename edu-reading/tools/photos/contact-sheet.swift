import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers
let sp=CommandLine.arguments[1], words=Array(CommandLine.arguments.dropFirst(2))
let cell:CGFloat=150, pad:CGFloat=6, lab:CGFloat=20
let fm=FileManager.default
var rows:[(String,[String])]=[]
for w in words {
  let fs=((try? fm.contentsOfDirectory(atPath: sp+"/cand2")) ?? [])
    .filter{ $0.hasPrefix(w+"__") && $0.hasSuffix(".jpg") }.sorted()
  if !fs.isEmpty { rows.append((w,fs)) }
}
let cols=4
let W=CGFloat(cols)*(cell+pad)+pad+90, H=CGFloat(rows.count)*(cell+pad)+pad
let c=CGContext(data:nil,width:Int(W),height:Int(H),bitsPerComponent:8,bytesPerRow:0,
 space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
c.setFillColor(CGColor(red:1,green:1,blue:1,alpha:1)); c.fill(CGRect(x:0,y:0,width:W,height:H))
for (r,(word,fs)) in rows.enumerated() {
  let y=H-pad-CGFloat(r+1)*(cell+pad)
  let a=NSAttributedString(string:word,attributes:[
    kCTFontAttributeName as NSAttributedString.Key: CTFontCreateWithName("Helvetica-Bold" as CFString,17,nil),
    kCTForegroundColorAttributeName as NSAttributedString.Key: CGColor(red:0,green:0,blue:0,alpha:1)])
  c.textPosition=CGPoint(x:6,y:y+cell/2); CTLineDraw(CTLineCreateWithAttributedString(a),c)
  for (i,f) in fs.prefix(cols).enumerated() {
    guard let s=CGImageSourceCreateWithURL(URL(fileURLWithPath:sp+"/cand2/"+f) as CFURL,nil),
          let im=CGImageSourceCreateImageAtIndex(s,0,nil) else { continue }
    let x=90+pad+CGFloat(i)*(cell+pad)
    let ar=CGFloat(im.width)/CGFloat(im.height)
    let w2 = ar>1 ? cell : cell*ar, h2 = ar>1 ? cell/ar : cell
    c.draw(im,in:CGRect(x:x+(cell-w2)/2,y:y+(cell-h2)/2,width:w2,height:h2))
    let n=NSAttributedString(string:"\(i)",attributes:[
      kCTFontAttributeName as NSAttributedString.Key: CTFontCreateWithName("Helvetica-Bold" as CFString,13,nil),
      kCTForegroundColorAttributeName as NSAttributedString.Key: CGColor(red:0.85,green:0.1,blue:0.1,alpha:1)])
    c.textPosition=CGPoint(x:x+3,y:y+3); CTLineDraw(CTLineCreateWithAttributedString(n),c)
  }
}
let out=CGImageDestinationCreateWithURL(URL(fileURLWithPath:sp+"/s2_\(words[0]).png") as CFURL,
 UTType.png.identifier as CFString,1,nil)!
CGImageDestinationAddImage(out,c.makeImage()!,nil); CGImageDestinationFinalize(out)
print("sheet: s2_\(words[0]).png  rows=\(rows.count)")
