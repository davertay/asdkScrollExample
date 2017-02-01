//
//  ViewController.swift
//  ASScrollTest
//
//  Created by David Taylor on 1/30/17.
//  Copyright © 2017 David Taylor. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class FlagNode: ASDisplayNode {
    var desc: String = ""
    var height: CGFloat = 44

    override func calculateSizeThatFits(_ constrainedSize: CGSize) -> CGSize {
        return CGSize(width: constrainedSize.width, height: height)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("tapped " + desc)
    }
}

class ContentNode: ASDisplayNode {
    private(set) var calculatedContentSize: CGSize = .zero

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let nodeSpecs: [(String, UIColor, CGFloat)] = [
            ("red", UIColor.red, 80),
            ("yellow", UIColor.yellow, 40),
            ("blue", UIColor.blue, 120),
            ("green", UIColor.green, 300),
            ("orange", UIColor.orange, 10),
            ("black", UIColor.black, 160),
            ("cyan", UIColor.cyan, 100),
        ]
        let verticalNodes:[ASLayoutElement] = nodeSpecs.map { (spec: (String, UIColor, CGFloat)) -> ASLayoutElement in
            let node = FlagNode()
            node.desc = spec.0
            node.backgroundColor = spec.1
            node.height = spec.2
            node.style.width = ASDimensionMake(ASDimensionUnit.fraction, 1.0)
            return node
        }
        let verticalStack = ASStackLayoutSpec.vertical()
        verticalStack.children = verticalNodes
        return verticalStack
    }

    private func calculateContentSize() -> CGSize {
        let verticalLayouts = calculatedLayout?.sublayouts
        let addLayoutHeight = { (sum: CGFloat, layout: ASLayout) -> CGFloat in
            return sum + layout.size.height
        }
        if let summedLayoutHeight = verticalLayouts?.reduce(0, addLayoutHeight) {
            return CGSize(width: calculatedSize.width, height: summedLayoutHeight)
        }
        return calculatedSize
    }

    override func layout() {
        super.layout()
        calculatedContentSize = calculateContentSize()
        print("calculatedContentSize: \(calculatedContentSize) frame: \(view.frame)")
    }

    func calculatePreferredLayoutSize(constrainedSize: ASSizeRange) -> CGSize {
        let verticalLayouts = layoutThatFits(constrainedSize).sublayouts
        let maxLayoutSize = { (maxSize: CGSize, layout: ASLayout) -> CGSize in
            let maxWidth = max(maxSize.width, layout.frame.maxX)
            let maxHeight = max(maxSize.height, layout.frame.maxY)
            return CGSize(width: maxWidth, height: maxHeight)
        }
        return verticalLayouts.reduce(constrainedSize.max, maxLayoutSize)
    }

    func forceStyleSize(size: CGSize) {
        style.width = ASDimensionMake(size.width)
        style.height = ASDimensionMake(size.height)
        style.minSize = size
        style.maxSize = size
        style.preferredSize = size
    }
}

class ViewController: ASViewController<ASScrollNode> {
    let autoContentSize = false
    let contentNode: ContentNode

    required init?(coder aDecoder: NSCoder) {
        let contentNode = ContentNode()
        contentNode.automaticallyManagesSubnodes = true
        contentNode.backgroundColor = UIColor.white
        self.contentNode = contentNode

        let scrollNode = ASScrollNode()
        scrollNode.automaticallyManagesSubnodes = true
        scrollNode.automaticallyManagesContentSize = autoContentSize
        scrollNode.backgroundColor = UIColor.lightGray
        scrollNode.style.width = ASDimensionMake(ASDimensionUnit.fraction, 1.0)
        scrollNode.layoutSpecBlock = { (node, constrainedSize) in
            let contentSize = contentNode.calculatePreferredLayoutSize(constrainedSize: constrainedSize)
            contentNode.forceStyleSize(size: contentSize)
            contentNode.style.layoutPosition = CGPoint(x: 0, y: 0)
            return ASAbsoluteLayoutSpec(sizing: .default, children: [contentNode])
        }
        super.init(node: scrollNode)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !autoContentSize {
            let newContentSize = contentNode.calculatedContentSize
            if newContentSize != .zero && newContentSize != node.view.contentSize {
                node.view.contentSize = newContentSize
            }
        }
    }
}
