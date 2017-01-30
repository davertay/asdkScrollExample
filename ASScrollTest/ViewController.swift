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
    var height: CGFloat = 44

    override func calculateSizeThatFits(_ constrainedSize: CGSize) -> CGSize {
        return CGSize(width: constrainedSize.width, height: height)
    }
}

class ContentNode: ASDisplayNode {
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let nodeSpecs: [(UIColor, CGFloat)] = [
            (UIColor.red, 80),
            (UIColor.yellow, 40),
            (UIColor.blue, 120),
            (UIColor.green, 300),
            (UIColor.orange, 10),
            (UIColor.black, 160),
            (UIColor.cyan, 100),
        ]
        let verticalNodes:[ASLayoutElement] = nodeSpecs.map { (spec: (UIColor, CGFloat)) -> ASLayoutElement in
            let node = FlagNode()
            node.backgroundColor = spec.0
            node.height = spec.1
            return node
        }
        let verticalStack = ASStackLayoutSpec.vertical()
        verticalStack.children = verticalNodes
        return verticalStack
    }
}

class ViewController: ASViewController<ASScrollNode> {
    required init?(coder aDecoder: NSCoder) {
        let contentNode = ContentNode()
        contentNode.automaticallyManagesSubnodes = true
        contentNode.backgroundColor = UIColor.white

        let scrollNode = ASScrollNode()
        scrollNode.automaticallyManagesSubnodes = true
        scrollNode.automaticallyManagesContentSize = true
        scrollNode.backgroundColor = UIColor.lightGray
        scrollNode.layoutSpecBlock = { (node, constrainedSize) in
            return ASAbsoluteLayoutSpec(sizing: .default, children: [contentNode])
        }
        super.init(node: scrollNode)
    }
}
