//
//  MVPDTableViewController.swift
//  RootSports
//
//  Created by Olena Lysenko on 10/29/18.
//  Copyright © 2018 Ooyala. All rights reserved.
//

import UIKit

class MVPDTableViewController: UITableViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var headerLabel: UILabel! {
        didSet {
            headerLabel.textColor = Branding.loginNavigationSubtitleColor
            headerLabel.font = Branding.loginNavigationSubtitleFont
        }
    }

    var mvpds: [Any]! = []
    var searchResults = [MVPD]()

    var selectionHandler: ((_ mvpd: MVPD) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Branding
        searchBar.barTintColor = Branding.mvpdSearchBackgroundColor
        searchBar.isTranslucent = true
        searchBar.alpha = 1
        searchBar.backgroundImage = UIImage()

        let searchTextField = searchBar.subviews.first?.subviews
            .first(where: { $0.isKind(of: UITextField.self) }) as? UITextField

        searchTextField?.backgroundColor = Branding.mvpdSearchFieldColor
        searchTextField?.textColor = Branding.mvpdSearchTextColor
        searchTextField?.font = Branding.mvpdSearchFont
        searchBar.tintColor = Branding.mvpdSearchTintColor

        tableView.backgroundColor = Branding.mvpdSearchBackgroundColor
        tableView.separatorColor = Branding.mvpdSearchSeparatorColor

        searchBar.placeholder = "Search Provider"

        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !searchBarIsEmpty() {
            return searchResults.count
        }

        return mvpds.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        cell.contentView.backgroundColor = Branding.mvpdSearchBackgroundColor
        cell.backgroundColor = Branding.mvpdSearchBackgroundColor
        cell.textLabel?.textColor = Branding.mvpdSearchTextColor
        cell.textLabel?.font = Branding.mvpdSearchFont

        if !searchBarIsEmpty() {
            let mvpd = searchResults[indexPath.row]
            cell.textLabel?.text = mvpd.displayName
        } else if let mvpd = mvpds[indexPath.row] as? MVPD {
            cell.textLabel?.text = mvpd.displayName
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let selectionHandler = selectionHandler else {
            return
        }

        if !searchBarIsEmpty() {
            let mvpd = searchResults[indexPath.row]
            selectionHandler(mvpd)
        } else if let mvpd = mvpds[indexPath.row] as? MVPD {
            selectionHandler(mvpd)
        }
    }
}

extension MVPDTableViewController: UISearchBarDelegate {

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            searchResults = filterData(searchText)

            tableView.reloadData()

        } else {
            searchResults.removeAll()
            tableView.reloadData()
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
    }

    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchBar.text?.isEmpty ?? true
    }

    func filterData(_ searchText: String) -> [MVPD] {
        return mvpds.filter { (row) -> Bool in
            if let mvpd = row as? MVPD {
                if mvpd.displayName.lowercased().contains(searchText.lowercased()) {
                    return true
                }
            }

            return false
            } as? [MVPD] ?? []
    }
}
