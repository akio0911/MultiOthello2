//
//  SingletonSocketIO.swift
//  MultiOthello
//
//  Created by 泉芳樹 on 2022/02/14.
//

import SocketIO

class SingletonSocketIO {
    private let manager = SocketManager(socketURL: URL(string:"https://multi-othello.com/")!, config: [.log(true), .compress])

    public static let shared = SingletonSocketIO()

    private init() {}

    func getSocket() -> SocketIOClient {
        return manager.defaultSocket
    }
}
struct ConfirmSocketID : SocketData {
    let tableid: String
    let name: String
    let userid: String
    let turn: Int
    let socketid: String
    func socketRepresentation() -> SocketData {
        return ["tableid": tableid, "name": name, "userid": userid, "turn": turn, "socketid": socketid]
    }
}
struct CustomData : SocketData {
    let id: String
    let x: Int
    let y: Int
    let turn: Int
    func socketRepresentation() -> SocketData {
        return ["id": id, "x": x, "y": y, "turn": turn]
    }
}
struct JoinData : SocketData {
    let tableid: String
    let name: String
    let userid: String
    func socketRepresentation() -> SocketData {
        return ["tableid": tableid, "name": name, "userid": userid]
    }
}
struct GameStartData : SocketData {
    let tableid: String
    func socketRepresentation() -> SocketData {
        return ["tableid": tableid]
    }
}
struct GameFinishData : SocketData {
    let tableid: String
    func socketRepresentation() -> SocketData {
        return ["tableid": tableid]
    }
}
