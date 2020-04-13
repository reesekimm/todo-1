//
//  TempVCViewController.swift
//  ToDoListApp
//
//  Created by Cory Kim on 2020/04/07.
//  Copyright © 2020 corykim0829. All rights reserved.
//

import UIKit

class ColumnViewController: UIViewController, NewCardDelegation {
    
    static let identifier = "Column"
    
    @IBOutlet weak var columnView: ColumnView!
    @IBOutlet weak var badgeView: BadgeView!
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var columnNameLabel: UILabel!
    @IBOutlet weak var addCardButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    let cardListDataSource = CardListDataSource()
    let cardListDelegate = CardListDelegate()
    
    var columnViewModel: ColumnViewModel? { didSet { configureViewModelHandler() } }
    private var cardListViewModel = CardListViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureColumnView()
        configureTableView()
    }
    
    func updateColumn(_ column: Column) {
        columnViewModel?.updateColumn(column)
    }
    
    private func configureViewModelHandler() {
        columnViewModel?.updateNotify(changed: { (column) in
            self.updateColumn(column)
            self.cardListViewModel.updateCardList(column?.cards)
        })
        cardListViewModel.updateNotify { (cardList) in
            self.cardListDataSource.updateCardList(cardList)
        }
    }
    
    private func configureTableView() {
        tableView.dataSource = cardListDataSource
        tableView.delegate = cardListDelegate
    }
    
    private func configureColumnView() {
        columnView.badgeView = badgeView
        columnView.badgeLabel = badgeLabel
        columnView.nameLabel = columnNameLabel
        columnView.addCardButton = addCardButton
    }
    
    private func updateColumn(_ column: Column?) {
        guard let column = column else { return }
        columnView.updateName(column.name)
        columnView.updateBadge(column.cards)
        cardListDataSource.updateCardList(column.cards)
        tableView.reloadData()
    }
    
    @IBAction func addNewCardButtonTapped(_ sender: Any) {
        guard let newCardViewController = storyboard?.instantiateViewController(withIdentifier: "newCard") as? NewCardViewController else { return }
        present(newCardViewController, animated: true, completion: {
            newCardViewController.newCardDelegate = self
        })
    }
    
    func addNewCard(_ card: Card) {
        tableView.beginUpdates()
        cardListViewModel.insertCard(card, at: 0)
        tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
        tableView.endUpdates()
    }
}
