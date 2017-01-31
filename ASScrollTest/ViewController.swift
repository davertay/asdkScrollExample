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
    private(set) var calculatedContentSize: CGSize = .zero

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
    }
}

class ViewController: ASViewController<ASScrollNode> {
    let autoContentSize = true
    let contentNode: ContentNode

    required init?(coder aDecoder: NSCoder) {
        let contentNode = ContentNode()
        contentNode.automaticallyManagesSubnodes = true
        contentNode.backgroundColor = UIColor.white
        contentNode.style.width = ASDimensionMake(ASDimensionUnit.fraction, 1.0)
        self.contentNode = contentNode

        let scrollNode = ASScrollNode()
        scrollNode.automaticallyManagesSubnodes = true
        scrollNode.automaticallyManagesContentSize = autoContentSize
        scrollNode.backgroundColor = UIColor.lightGray
        scrollNode.style.width = ASDimensionMake(ASDimensionUnit.fraction, 1.0)
        scrollNode.layoutSpecBlock = { (node, constrainedSize) in
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
