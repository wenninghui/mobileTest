//
//  BookingListViewController.swift
//  MobileTest
//
//  Created by wen ninghui on 2025/9/2.
//

import UIKit

class BookingListViewController: UIViewController {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let refresh = UIRefreshControl()
    private var bookingDataManager: BookingDataManager = BookingDataManager()

    private var booking: Booking?
    private var segments: [Segment] = []


    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Bookings"
        view.backgroundColor = .systemBackground
        setupTable()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData(trigger: "viewWillAppear")
    }
    
    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self

        refresh.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
        tableView.refreshControl = refresh
    }
    
    @objc private func onPullToRefresh() {
        loadData(trigger: "pullToRefresh", policy: .refreshOnly)
    }

    private func loadData(trigger: String, policy: FetchPolicy = .cacheFirstThenRefresh) {
        if !refresh.isRefreshing { refresh.beginRefreshing() }
        bookingDataManager.fetchBooking(policy: policy) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                self.refresh.endRefreshing()
                switch result {
                case .success(let booking):
                    self.apply(booking: booking, source: "completion", trigger: trigger)
                case .failure(let error):
                    print("error:=\(error.localizedDescription)")
                }
            }
        } onUpdate: { [weak self] booking in
            guard let self else { return }
            DispatchQueue.main.async {
                self.apply(booking: booking, source: "update", trigger: trigger)
            }
        }
    }
    

    private func apply(booking: Booking, source: String, trigger: String) {
        self.booking = booking
        self.segments = booking.segments
        print("[ListVC] trigger=\(trigger) source=\(source) booking=\(booking)")
        tableView.reloadData()
    }

}

extension BookingListViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        segments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let seg = segments[indexPath.row]
        let pair = seg.originAndDestinationPair
        cell.textLabel?.text = "#\(seg.id)  \(pair.origin.code) → \(pair.destination.code)"
        cell.detailTextLabel?.text = nil
        cell.accessoryType = .disclosureIndicator
        var content = cell.defaultContentConfiguration()
        content.text = cell.textLabel?.text
        content.secondaryText = "\(pair.originCity) → \(pair.destinationCity)"
        cell.contentConfiguration = content
        return cell
    }
}
