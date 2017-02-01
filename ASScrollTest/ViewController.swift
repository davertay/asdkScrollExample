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
    let descr: String
    let height: CGFloat

    init(descr: String, color: UIColor, height: CGFloat) {
        self.descr = descr
        self.height = height
        super.init()
        backgroundColor = color
        style.width = ASDimensionMake(ASDimensionUnit.fraction, 1.0)
    }

    override func calculateSizeThatFits(_ constrainedSize: CGSize) -> CGSize {
        return CGSize(width: constrainedSize.width, height: height)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("tapped " + descr)
    }
}

class ContentNode: ASDisplayNode {
    let verticalNodes: [ASLayoutElement]

    override init() {
        verticalNodes = [
            FlagNode(descr: "red", color: UIColor.red, height: 80),
            FlagNode(descr: "yellow", color: UIColor.yellow, height: 40),
            FlagNode(descr: "blue", color: UIColor.blue, height: 120),
            FlagNode(descr: "green", color: UIColor.green, height: 300),
            FlagNode(descr: "orange", color: UIColor.orange, height: 10),
            FlagNode(descr: "black", color: UIColor.black, height: 160),
            FlagNode(descr: "cyan", color: UIColor.cyan, height: 100),
        ]
        super.init()
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let verticalStack = ASStackLayoutSpec.vertical()
        verticalStack.children = verticalNodes
        return verticalStack
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
    let autoContentSize = true
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
            let newContentSize = contentNode.style.preferredSize
            if newContentSize != .zero && newContentSize != node.view.contentSize {
                node.view.contentSize = newContentSize
            }
        }
    }
}
