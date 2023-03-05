//
//  MockCurrencyRateListViewModel.swift
//  PayPay DemoTests
//
//  Created by Mahbubur Rashid Leon on 26/7/22.
//

import Foundation
import Combine

@testable import PayPay_Demo

class MockCurrencyRateListViewModel: CurrencyRateListViewModelProtocol {
    @LocalStorage(key: .currencyConversionRateList, defaultValue: [:])
    var localCurrencyRateList: [String: Double]

    @Published var currencyRateList: [String: Double]?

    var subscription: Set<AnyCancellable> = []

    var viewModel: CurrencyViewModel?

    init() {
        viewModel = CurrencyViewModel()
    }

    func fetchCurrencyRateList() {
        guard let viewModel = viewModel else {
            return
        }

        if localCurrencyRateList.count > 0 && viewModel.isNotMoreThan30Min() {
            currencyRateList = localCurrencyRateList
        } else {
            Task {
                let params = [
                    "app_id": APP_ID
                ] as? [String: Any]

                _ = await fetchCurrencyRatesFromAPI(apiURL: .LATEST_JSON, params: params)
                viewModel.lastAPIFetchedTime = Date.now
            }
        }
    }

    func fetchCurrencyRatesFromAPI(apiURL: HttpURL, params: [String: Any]?) async -> String? {
        let (result, error) = await RequestManager.shared.request(using: apiURL, queryParams: params, parameterType: .query, type: .get)

        if let error = error {
            switch error {
            case .noInternet:
                return "No Internet"
            case .unknownError:
                return "Unknown Error"
            case .errorDescription,
                    .networkProblem:
                return "Network Problem"
            }
        }

        guard let result = result else {
            return "Data retrieve error"
        }

        let json = try? JSONSerialization.jsonObject(with: result, options: .mutableContainers) as? [String: AnyObject]

        // Converting data into Dictionary
        let currencyRateList: [String: Double] = json?["rates"] as! [String: Double]

        self.currencyRateList = currencyRateList
        localCurrencyRateList = currencyRateList

        return nil
    }
}
