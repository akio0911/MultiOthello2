//
//  TableViewCell.swift
//  MultiOthello
//
//  Created by 泉芳樹 on 2022/01/03.
//

import UIKit

class TableViewCell: UITableViewCell {
    @IBOutlet weak var dateTimeLabel: UILabel!
    @IBOutlet weak var maxNumberLabel: UILabel!
    @IBOutlet weak var tableNameLabel: UILabel!
    private var id: String?
    func configure(dateTime: String, maxNumber: Int, tableName: String, id: String) {
        self.id = id
        self.dateTimeLabel.text = dateTime
        self.maxNumberLabel.text = String(maxNumber) + "人"
        if tableName == "" {
            self.tableNameLabel.text = "no name"
        } else {
            self.tableNameLabel.text = tableName
        }
    }
    func nextViewController(data: Data?) {
        do {
            let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments)
            DispatchQueue.main.async {
                let parentVC = self.parentViewController() as! TableListViewController
                let docs : Bool = (json as! NSDictionary)["playinggame"] as! Bool
                if docs {
                    let nextVC = parentVC.storyboard?.instantiateViewController(withIdentifier: "TabBarController") as! TabBarController
                    let tableListView = nextVC.viewControllers?[1] as! TableListViewController
                    tableListView.getTableList()
                    nextVC.selectedViewController = tableListView
                    nextVC.modalPresentationStyle = .fullScreen
                    parentVC.present(nextVC, animated: true, completion: nil)
                } else {
                    let nextVC = parentVC.storyboard?.instantiateViewController(withIdentifier: "GameViewController") as! GameViewController
                    nextVC.modalPresentationStyle = .fullScreen
                    nextVC.configure(tableID: self.id!)
                    parentVC.present(nextVC, animated: true, completion: nil)

                }
            }
        } catch {
            print ("json error")
            return
        }

    }
    @IBAction func joinButtonTapped(_ sender: Any) {
        let serverRequest: ServerRequest = ServerRequest()
        serverRequest.sendServerRequest(
            urlString: "https://multi-othello.com/isPlayingGame",
            params: [
                "tableid": self.id!
            ],
            completion: self.nextViewController)
    }
}
