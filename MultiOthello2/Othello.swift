//
//  Othello.swift
//  MultiOthello2
//
//  Created by 泉芳樹 on 2022/02/27.
//

import SocketIO
import RealmSwift
import SpriteKit

class Othello {
    private let EMPTY_AREA = -1
    private let PUTTABLE_AREA = 777
    private var socket: SocketIOClient!
    private var dataList: NSArray! = []
    private var putData: NSArray! = []
    private var joinData: NSArray! = []
    private var gameStartData: NSArray! = []
    private var boardsColorNumber: [[Int]] = []
    private var points: [Int] = []
    private var tableID: String?
    private var userID: String?
    private var myName: String?
    private var myTurn: Int?
    private var turn: Int = 0
    private var playerMaxNumber: Int?
    private var isPassTurn: Bool = false
    private var isGameFinish: Bool = false
    private var isGameStart: Bool = false
    private var isGameButtonActive: Bool = false

    let COLORS: [UIColor] = [
        UIColor.init(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0), // red
        UIColor.init(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0), // green
        UIColor.init(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0), // blue
        UIColor.init(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0), // yellow
        UIColor.init(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0), // purple
        UIColor.init(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0), // cyan
        UIColor.init(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0), // black
        UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), // white
        UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0), // gray
    ]

    init() {
        socket = SingletonSocketIO.shared.getSocket()

        socket.on(clientEvent: .connect){ data, ack in
            print("socket connected!")
            let realm = try! Realm()
            let account: Results<Account> = realm.objects(Account.self)

            if account.count >= 1 {
                self.myName = account[0].name
                self.userID = account[0].userid
                self.socket.emit("join", JoinData(tableid: self.tableID!, name: account[0].name, userid: account[0].userid))
            }
        }

        socket.on(clientEvent: .disconnect){data, ack in
            print("socket disconnected!")
        }
        socket.on("disconnected"){data, ask in
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let json = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as! NSArray
                print(json)
//                self.putData = json as NSArray
            } catch {
                print("#####error")
                return
            }
        }

        socket.on("drag"){data, ack in
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let json = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as! NSArray
                self.dataList = json[0] as? NSArray
            } catch {
                print("#####error")
                return
            }
        }

        socket.on("put"){data, ack in
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let json = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as! NSArray
                self.putData = json as NSArray
            } catch {
                print("#####error")
                return
            }
        }

        socket.on("join"){data, ack in
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let json = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as! NSArray
                self.joinData = json as NSArray
            } catch {
                print("#####error")
                return
            }
        }
        socket.on("gameStart"){data, ack in
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let json = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as! NSArray
                self.gameStartData = json as NSArray
            } catch {
                print("#####error")
                return
            }
        }

        socket.connect()

    }

    func gameFinish() {
        guard let tableID = tableID else {
            return
        }
        socket.emit("gameFinish", GameFinishData(tableid: tableID))
        socket.emit("disconnect")
    }
    func gameStart() {
        guard let tableID = tableID else {
            return
        }
        socket.emit("gameStart", GameStartData(tableid: tableID))
    }

    func put(node: SKShapeNode, boards: [[SKShapeNode]]) {
        guard let playerMaxNumber = playerMaxNumber else {
            return
        }
        var y = 0
        for_i : for boardRow in boards {
            var x = 0
            for board in boardRow {
                if node == board {
                    if boardsColorNumber[y][x] != PUTTABLE_AREA && // 設置しようとした場所が設置可能エリア以外はスキップする
                        (turn >= (playerMaxNumber * 2)) { // 1人2コマ置くまでは設置処理はスキップする
                        break for_i
                    }
                    for yy in 0...7 {
                        for xx in 0...7 {
                            if boardsColorNumber[yy][xx] == PUTTABLE_AREA { //設置可能エリアがある場合
                                boardsColorNumber[yy][xx] = EMPTY_AREA //空のエリアにする
                            }
                        }
                    }
                    boards[y][x].fillColor = COLORS[turn % playerMaxNumber] //設置場所を自分の色にする
                    boardsColorNumber[y][x] = turn % playerMaxNumber //設置場所を自分の番号にする
                    socket.emit("put", CustomData(id: self.tableID!, x: x, y: y, turn: turn)) // サーバーに設置場所と手番を送信
                    break for_i //処理を抜ける
                }
                x += 1
            }
            y += 1
        }
    }

    func setTableID(tableID: String) {
        self.tableID = tableID
    }

    func appendBoardsColorNumberRow(boardsColorNumberRow: [Int]) {
        boardsColorNumber.append(boardsColorNumberRow)
    }

    func appendPoints(point: Int) {
        points.append(point)
    }

    func setGameStartFlag(flag: Bool) {
        isGameStart = flag
    }

    func getGameStartFlag() -> Bool {
        return isGameStart
    }

    func isMyTurn() -> Bool {
        guard let playerMaxNumber = playerMaxNumber else {
            return false
        }
        return myTurn == turn % playerMaxNumber
    }

    func getBoardsColorNumber() -> [[Int]] {
        return boardsColorNumber
    }

    func getMyName() -> String {
        guard let myName = myName else {
            return "" // エラー処理が必要かも？
        }
        return myName
    }

    func getPoints(turn: Int) -> Int {
        return points[turn]
    }

    func setPoints(turn: Int, value: Int) {
        points[turn] = value
    }

    func incrementPoints(turn: Int) {
        points[turn] += 1
    }

    func fillColorBoards(boards: [[SKShapeNode]]) {
        for yy in 0...7 {
            for xx in 0...7 {
                if boardsColorNumber[yy][xx] == PUTTABLE_AREA {
                    boardsColorNumber[yy][xx] = EMPTY_AREA
                }
            }
        }
        for yy in 0...7 {
            for xx in 0...7 {
                if boardsColorNumber[yy][xx] == PUTTABLE_AREA || boardsColorNumber[yy][xx] == EMPTY_AREA {
                    boards[yy][xx].fillColor = UIColor.init(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
                }
            }
        }
        for t in 0...7 {
            for yy in 0...7 {
                for xx in 0...7 {
                    if boardsColorNumber[yy][xx] == t {
                        boards[yy][xx].fillColor = COLORS[t]
                    }
                }
            }
        }
    }

    func whereCanIPutAPiece(t: Int) {
        guard let playerMaxNumber = playerMaxNumber else {
            return
        }
        let turn = t % playerMaxNumber
        for yy in 0...7 {
            for xx in 2...7 {
                if boardsColorNumber[yy][xx] == turn {
                    var xxxx = 0
                    for xxx in 1...xx {
                        if boardsColorNumber[yy][xx - xxx] != EMPTY_AREA &&
                           boardsColorNumber[yy][xx - xxx] != turn &&
                           boardsColorNumber[yy][xx - xxx] != PUTTABLE_AREA {
                            xxxx = xxx
                        } else {
                            break
                        }
                    }
                    if xxxx >= 1 && xxxx < xx && boardsColorNumber[yy][xx - xxxx - 1] == EMPTY_AREA {
                        boardsColorNumber[yy][xx - xxxx - 1] = PUTTABLE_AREA
                        break
                    }
                }
            }
            for xx in 0...5 {
                if boardsColorNumber[yy][xx] == turn && xx < 6 {
                    var xxxx = 0
                    for xxx in (xx + 1)...6 {
                        if boardsColorNumber[yy][xxx] != EMPTY_AREA &&
                           boardsColorNumber[yy][xxx] != turn &&
                           boardsColorNumber[yy][xxx] != PUTTABLE_AREA {
                            xxxx = xxx
                        } else {
                            break
                        }
                    }
                    if xxxx >= 1 && boardsColorNumber[yy][xxxx + 1] == EMPTY_AREA {
                        boardsColorNumber[yy][xxxx + 1] = PUTTABLE_AREA
                        break
                    }
                }
            }
        }
        for xx in 0...7 {
            for yy in 2...7 {
                if boardsColorNumber[yy][xx] == turn {
                    var yyyy = 0
                    for yyy in 1...yy {
                        if boardsColorNumber[yy - yyy][xx] != EMPTY_AREA &&
                           boardsColorNumber[yy - yyy][xx] != turn &&
                           boardsColorNumber[yy - yyy][xx] != PUTTABLE_AREA {
                            yyyy = yyy
                        } else {
                            break
                        }
                    }
                    if yyyy >= 1 && yyyy < yy && boardsColorNumber[yy - yyyy - 1][xx] == EMPTY_AREA {
                        boardsColorNumber[yy - yyyy - 1][xx] = PUTTABLE_AREA
                        break
                    }
                }
            }
            for yy in 0...5 {
                if boardsColorNumber[yy][xx] == turn && yy < 6 {
                    var yyyy = 0
                    for yyy in (yy + 1)...6 {
                        if boardsColorNumber[yyy][xx] != EMPTY_AREA &&
                           boardsColorNumber[yyy][xx] != turn &&
                           boardsColorNumber[yyy][xx] != PUTTABLE_AREA {
                            yyyy = yyy
                        } else {
                            break
                        }
                    }
                    if yyyy >= 1 && boardsColorNumber[yyyy + 1][xx] == EMPTY_AREA {
                        boardsColorNumber[yyyy + 1][xx] = PUTTABLE_AREA
                        break
                    }
                }
            }
        }
        for xx in 0...7 {
            for yy in 0...7 {
                if boardsColorNumber[yy][xx] == turn {
                    var zzzz = 0
                    for zzz in 1...7 {
                        if yy >= zzz && xx >= zzz &&
                           boardsColorNumber[yy - zzz][xx - zzz] != EMPTY_AREA &&
                           boardsColorNumber[yy - zzz][xx - zzz] != turn &&
                           boardsColorNumber[yy - zzz][xx - zzz] != PUTTABLE_AREA {
                            zzzz = zzz
                        } else {
                            break
                        }
                    }
                    if zzzz >= 1 && yy > zzzz && xx > zzzz && boardsColorNumber[yy - zzzz - 1][xx - zzzz - 1] == EMPTY_AREA {
                        boardsColorNumber[yy - zzzz - 1][xx - zzzz - 1] = PUTTABLE_AREA
                    }
                }
            }
        }
        for xx in 0...7 {
            for yy in 0...7 {
                if boardsColorNumber[yy][xx] == turn {
                    var zzzz = 0
                    for zzz in 1...6 {
                        if yy + zzz <= 7 && xx + zzz <= 7 &&
                           boardsColorNumber[yy + zzz][xx + zzz] != EMPTY_AREA &&
                           boardsColorNumber[yy + zzz][xx + zzz] != turn &&
                           boardsColorNumber[yy + zzz][xx + zzz] != PUTTABLE_AREA {
                            zzzz = zzz
                        } else {
                            break
                        }
                    }
                    if zzzz >= 1 && yy + zzzz < 7 && xx + zzzz < 7 && boardsColorNumber[yy + zzzz + 1][xx + zzzz + 1] == EMPTY_AREA {
                        boardsColorNumber[yy + zzzz + 1][xx + zzzz + 1] = PUTTABLE_AREA
                    }
                }
            }
        }
        for xx in 0...7 {
            for yy in 0...7 {
                if boardsColorNumber[yy][xx] == turn {
                    var zzzz = 0
                    for zzz in 1...6 {
                        if yy + zzz <= 7 && xx >= zzz &&
                           boardsColorNumber[yy + zzz][xx - zzz] != EMPTY_AREA &&
                           boardsColorNumber[yy + zzz][xx - zzz] != turn &&
                           boardsColorNumber[yy + zzz][xx - zzz] != PUTTABLE_AREA {
                            zzzz = zzz
                        } else {
                            break
                        }
                    }
                    if zzzz >= 1 && yy + zzzz < 7 && xx > zzzz && boardsColorNumber[yy + zzzz + 1][xx - zzzz - 1] == EMPTY_AREA {
                        boardsColorNumber[yy + zzzz + 1][xx - zzzz - 1] = PUTTABLE_AREA
                    }
                }
            }
        }
        for xx in 0...7 {
            for yy in 0...7 {
                if boardsColorNumber[yy][xx] == turn {
                    var zzzz = 0
                    for zzz in 1...6 {
                        if xx + zzz <= 7 && yy >= zzz &&
                           boardsColorNumber[yy - zzz][xx + zzz] != EMPTY_AREA &&
                           boardsColorNumber[yy - zzz][xx + zzz] != turn &&
                           boardsColorNumber[yy - zzz][xx + zzz] != PUTTABLE_AREA {
                            zzzz = zzz
                        } else {
                            break
                        }
                    }
                    if zzzz >= 1 && xx + zzzz < 7 && yy > zzzz && boardsColorNumber[yy - zzzz - 1][xx + zzzz + 1] == EMPTY_AREA {
                        boardsColorNumber[yy - zzzz - 1][xx + zzzz + 1] = PUTTABLE_AREA
                    }
                }
            }
        }
    }
    func iCanPutAllPlace() {
        for yy in 0...7 {
            for xx in 0...7 {
                if boardsColorNumber[yy][xx] != EMPTY_AREA && boardsColorNumber[yy][xx] != PUTTABLE_AREA {
                    if xx > 0 && boardsColorNumber[yy][xx - 1] == EMPTY_AREA {
                        boardsColorNumber[yy][xx - 1] = PUTTABLE_AREA
                    }
                    if xx < 7 && boardsColorNumber[yy][xx + 1] == EMPTY_AREA {
                        boardsColorNumber[yy][xx + 1] = PUTTABLE_AREA
                    }
                    if yy > 0 && boardsColorNumber[yy - 1][xx] == EMPTY_AREA {
                        boardsColorNumber[yy - 1][xx] = PUTTABLE_AREA
                    }
                    if yy < 7 && boardsColorNumber[yy + 1][xx] == EMPTY_AREA {
                        boardsColorNumber[yy + 1][xx] = PUTTABLE_AREA
                    }

                    if xx > 0 && yy > 0 && boardsColorNumber[yy - 1][xx - 1] == EMPTY_AREA {
                        boardsColorNumber[yy - 1][xx - 1] = PUTTABLE_AREA
                    }
                    if xx < 7 && yy < 7 && boardsColorNumber[yy + 1][xx + 1] == EMPTY_AREA {
                        boardsColorNumber[yy + 1][xx + 1] = PUTTABLE_AREA
                    }
                    if xx > 0 && yy < 7 && boardsColorNumber[yy + 1][xx - 1] == EMPTY_AREA {
                        boardsColorNumber[yy + 1][xx - 1] = PUTTABLE_AREA
                    }
                    if xx < 7 && yy > 0 && boardsColorNumber[yy - 1][xx + 1] == EMPTY_AREA {
                        boardsColorNumber[yy - 1][xx + 1] = PUTTABLE_AREA
                    }

                }
            }
        }
    }
    func reversi(x: Int, y: Int, t: Int) {
        guard let playerMaxNumber = playerMaxNumber else {
            return
        }
        let turn = t % playerMaxNumber
        for_xx: for xx in 0...x {
            if boardsColorNumber[y][xx] == turn && (xx + 1) < x {
                for xxx in (xx + 1)...(x - 1) {
                    if boardsColorNumber[y][xxx] == EMPTY_AREA {
                        break for_xx
                    }
                    if boardsColorNumber[y][xxx] == turn {
                        continue for_xx
                    }
                }
                for xxx in xx...x {
                    boardsColorNumber[y][xxx] = turn
                }
                break
            }
        }
        if x < 7 {
            for_xx : for xx in (x + 1)...7 {
                if boardsColorNumber[y][xx] == turn && (x + 1) < xx {
                    for xxx in (x + 1)...(xx - 1) {
                        if boardsColorNumber[y][xxx] == EMPTY_AREA {
                            break for_xx
                        }
                        if boardsColorNumber[y][xxx] == turn {
                            continue for_xx
                        }
                    }
                    for xxx in x...xx {
                        boardsColorNumber[y][xxx] = turn
                    }
                    break
                }
            }
        }
        for_yy: for yy in 0...y {
            if boardsColorNumber[yy][x] == turn && (yy + 1) < y {
                for yyy in (yy + 1)...(y - 1) {
                    if boardsColorNumber[yyy][x] == EMPTY_AREA {
                        break for_yy
                    }
                    if boardsColorNumber[yyy][x] == turn {
                        continue for_yy
                    }
                }

                for yyy in yy...y {
                    boardsColorNumber[yyy][x] = turn
                }
                break
            }
        }
        if y < 7 {
            for_yy: for yy in (y + 1)...7 {
                if boardsColorNumber[yy][x] == turn && (y + 1) < yy {
                    for yyy in (y + 1)...(yy - 1) {
                        if boardsColorNumber[yyy][x] == EMPTY_AREA {
                            break for_yy
                        }
                        if boardsColorNumber[yyy][x] == turn {
                            continue for_yy
                        }
                    }
                    for yyy in y...yy {
                        boardsColorNumber[yyy][x] = turn
                    }
                    break
                }
            }
        }
        for_zz: for zz in 1...7 {
            if x + zz <= 7 && y + zz <= 7 && boardsColorNumber[y + zz][x + zz] == turn && zz > 1 {
                for zzz in 1...(zz - 1) {
                    if boardsColorNumber[y + zzz][x + zzz] == EMPTY_AREA {
                        break for_zz
                    }
                    if boardsColorNumber[y + zzz][x + zzz] == turn {
                        continue for_zz
                    }
                }
                for zzz in 0...zz {
                    boardsColorNumber[y + zzz][x + zzz] = turn
                }
                break
            }
        }
        for_zz: for zz in 1...7 {
            if x - zz >= 0 && y - zz >= 0 && boardsColorNumber[y - zz][x - zz] == turn && zz > 1 {
                for zzz in 1...(zz - 1) {
                    if boardsColorNumber[y - zzz][x - zzz] == EMPTY_AREA {
                        break for_zz
                    }
                    if boardsColorNumber[y - zzz][x - zzz] == turn {
                        continue for_zz
                    }
                }
                for zzz in 1...(zz - 1) {
                    boardsColorNumber[y - zzz][x - zzz] = turn
                }
                break
            }
        }
        for_zz: for zz in 1...7 {
            if x + zz <= 7 && y - zz >= 0 && boardsColorNumber[y - zz][x + zz] == turn && zz > 1 {
                for zzz in 1...(zz - 1) {
                    if boardsColorNumber[y - zzz][x + zzz] == EMPTY_AREA {
                        break for_zz
                    }
                    if boardsColorNumber[y - zzz][x + zzz] == turn {
                        continue for_zz
                    }
                }
                for zzz in 0...zz {
                    boardsColorNumber[y - zzz][x + zzz] = turn
                }
                break
            }
        }
        for_zz: for zz in 1...7 {
            if x - zz >= 0 && y + zz <= 7 && boardsColorNumber[y + zz][x - zz] == turn && zz > 1 {
                for zzz in 1...(zz - 1) {
                    if boardsColorNumber[y + zzz][x - zzz] == EMPTY_AREA {
                        break for_zz
                    }
                    if boardsColorNumber[y + zzz][x - zzz] == turn {
                        continue for_zz
                    }
                }
                for zzz in 0...zz {
                    boardsColorNumber[y + zzz][x - zzz] = turn
                }
                break
            }
        }
    }

    func getGameButtonFlag() -> Bool {
        return isGameButtonActive
    }

    func join(addGameStartButton: () -> Void, addWaitGameButton: () -> Void, labels: [SKLabelNode]) {
        guard let joinData = joinData else { return }
        for doc in joinData {
            let owner: String = ( (doc as! NSDictionary)["ownername"] as! String)
            if isGameButtonActive == false {
                isGameButtonActive = true
                if owner == myName {
                    addGameStartButton()
                } else {
                    addWaitGameButton()
                }
            }
            var i = 0
            let players: NSArray = ( (doc as! NSDictionary)["players"] as! NSArray)
            for player in players {
                let name: String = ( (player as! NSDictionary)["name"] as! String)
                labels[i].text = "●" + name
                if name == myName {
                    let socketid: String = ( (player as! NSDictionary)["socketid"] as! String)
                    socket.emit("confirm_socketid", ConfirmSocketID(tableid: tableID!, name: myName!, userid: userID!, turn: i, socketid: socketid))
                    myTurn = i
                }
                i += 1
                playerMaxNumber = i
            }
        }
    }

    func gameStart(hiddenWaitGameButton: () -> Void) {
        guard let gameStartData = gameStartData else { return }
        for doc in gameStartData {
            let gameStartTableId: String = ( (doc as! NSDictionary)["tableid"] as! String)
            isGameStart = true
            hiddenWaitGameButton()
        }
    }

    func updatePut(addGameFinishButton: () -> Void, hiddenPassTurnButton: () -> Void, visiblePassTurnButton: () -> Void, updatePointsLabel: () -> Void, boards: [[SKShapeNode]]) {
        guard let putData = putData else { return }
        for doc in putData {
            for yy in 0...7 {
                for xx in 0...7 {
                    if boardsColorNumber[yy][xx] == PUTTABLE_AREA { // 設置可能エリアは全て
                        boardsColorNumber[yy][xx] = EMPTY_AREA      // 空のエリアにする
                    }
                }
            }
            let x: Int = ( (doc as! NSDictionary)["x"] as! Int)    // x位置
            let y: Int = ( (doc as! NSDictionary)["y"] as! Int)    // y位置
            let t: Int = ( (doc as! NSDictionary)["turn"] as! Int) // 色（手番）
            if t >= 63 && isGameFinish == false { // 手番が最後の場合、ゲームが終了してない場合
                isGameFinish = true
                addGameFinishButton() // ゲーム終了ボタンを表示させる
            }
            if (x == -1 && y == -1) == false { // パスじゃない場合

                boards[y][x].fillColor = COLORS[t % playerMaxNumber!]
                boardsColorNumber[y][x] = t % playerMaxNumber!
                reversi(x: x, y: y, t: t)
                turn = t + 1
                self.fillColorBoards(boards: boards)
                updatePointsLabel()

                if (turn % playerMaxNumber!) == myTurn && turn >= playerMaxNumber! * 2 {
                    if points[myTurn!] == 0 {
                        iCanPutAllPlace()
                    } else {
                        whereCanIPutAPiece(t: turn)
                    }
                    var isPass: Bool = true
                    for yy in 0...7 {
                        for xx in 0...7 {
                            if boardsColorNumber[yy][xx] == PUTTABLE_AREA {
                                isPass = false
                                boards[yy][xx].fillColor = COLORS[8]
                            }
                        }
                    }
                    if isPass {
                        socket.emit("put", CustomData(id: self.tableID!, x: -1, y: -1, turn: turn))
                        visiblePassTurnButton()
                        self.fillColorBoards(boards: boards)
                        updatePointsLabel()
                    } else {
                        hiddenPassTurnButton()
                    }
                }
            } else { // パスの場合
                turn += 1
                if (turn % playerMaxNumber!) == myTurn {
                    whereCanIPutAPiece(t: turn) // 置ける場所を
                    for yy in 0...7 {
                        for xx in 0...7 {
                            if boardsColorNumber[yy][xx] == PUTTABLE_AREA {
                                boards[yy][xx].fillColor = COLORS[8]
                            }
                        }
                    }
                }
            }
            self.putData = nil
            break
        }
    }
}
