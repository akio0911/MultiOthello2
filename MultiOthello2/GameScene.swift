//
//  GameScene.swift
//  MultiOthello
//
//  Created by 泉芳樹 on 2021/12/21.
//

import SpriteKit
import GameplayKit
import SwiftUI

enum PuttablePieceResult {
    case pass
    case puttable
    case canNutPut
}

class GameScene: SKScene {
    private let othello: Othello = Othello()
    private var waitGameButton: SKSpriteNode = SKSpriteNode(imageNamed: "waitGame")
    private var gameStartButton: SKSpriteNode = SKSpriteNode(imageNamed: "gameStart")
    private var gameFinishButton: SKSpriteNode = SKSpriteNode(imageNamed: "gameFinish")
    private var passTurnButton: SKSpriteNode = SKSpriteNode(imageNamed: "pass")
    private var labels: [SKLabelNode] = []
    private var boards: [[SKShapeNode]] = []
    private var boardsCount: Int = 0
    private var gameClosure: (() -> Void)?

    func configure(tableID: String, closure: @escaping (() -> Void) ) {
        othello.setTableID(tableID: tableID)
        gameClosure = closure
    }

    override func didMove(to view: SKView) {

        let BOARD_SIZE: CGFloat = self.frame.width / 8
        let LINE_WIDTH: CGFloat = 4
        for y in 0...7 {
            var row: [SKShapeNode] = []
            var boardsColorNumberRow: [Int] = []
            for x in 0...7 {
                let board: SKShapeNode = SKShapeNode(rect: CGRect(x: CGFloat(x) * BOARD_SIZE - self.frame.width / 2, y: CGFloat(y) * BOARD_SIZE - self.frame.width / 2, width: BOARD_SIZE, height: BOARD_SIZE))
                board.fillColor = UIColor.init(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
                board.strokeColor = .black
                board.lineWidth = LINE_WIDTH
                addChild(board)
                row.append(board)
                boardsColorNumberRow.append(-1)
            }
            boards.append(row)
            othello.appendBoardsColorNumberRow(boardsColorNumberRow: boardsColorNumberRow)
        }


        for i in 0...7 {
            othello.appendPoints(point: 0)
            let label: SKLabelNode = SKLabelNode(text: "●12345678901234567890")
            label.position.x = -self.frame.width / 2 + label.frame.width / 2
            label.position.y = self.frame.height / 2 - CGFloat(i * 35) - 35
            label.fontColor = othello.COLORS[i]
            labels.append(label)
            addChild(label)
        }
        passTurnButton.isHidden = true
        addChild(passTurnButton)

    }

    func touchDown(atPoint pos : CGPoint) {
//        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
//            n.position = pos
//            n.strokeColor = SKColor.green
//            self.addChild(n)
//        }
    }

    func touchMoved(toPoint pos : CGPoint) {
//        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
//            n.position = pos
//            n.strokeColor = SKColor.blue
//            self.addChild(n)
//        }
    }

    func touchUp(atPoint pos : CGPoint) {
//        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
//            n.position = pos
//            n.strokeColor = SKColor.red
//            self.addChild(n)
//        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: self)
        if atPoint(location) == gameFinishButton {
            gameFinishButton.isHidden = true
            othello.gameFinish()
            gameClosure!()
            return
        }

        if atPoint(location) == gameStartButton {
            othello.setGameStartFlag(flag: true)
            gameStartButton.isHidden = true
            othello.gameStart()
            return
        }

        guard let node = atPoint(location) as? SKShapeNode else {
            return
        }

        if othello.getGameStartFlag() == false {
            return
        }

        if othello.isMyTurn() {
            othello.put(node: node, boards: boards)
        }
    }

    func pointsLabel() {
        for t in 0...7 {
            othello.setPoints(turn: t, value: 0)
            for boardRow2 in othello.getBoardsColorNumber() {
                for board2 in boardRow2 {
                    if board2 == t {
                        othello.incrementPoints(turn: t)
                    }
                }
            }
            labels[t].text = "●" + String(othello.getPoints(turn: t))
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }


    override func update(_ currentTime: TimeInterval) {
        othello.join(addGameStartButton: {
            addChild(gameStartButton)
        }, addWaitGameButton: {
            addChild(waitGameButton)
        }, labels: labels)

        othello.gameStart(hiddenWaitGameButton: {
            waitGameButton.isHidden = true
        })

        othello.updatePut(addGameFinishButton: {
            addChild(gameFinishButton)
        }, hiddenPassTurnButton: {
            passTurnButton.isHidden = true
        }, visiblePassTurnButton: {
            passTurnButton.isHidden = false
        }, updatePointsLabel: {
            pointsLabel()
        }, boards: boards)
    }
}
