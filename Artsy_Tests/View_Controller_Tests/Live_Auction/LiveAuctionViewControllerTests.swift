import Quick
import Nimble
import Nimble_Snapshots
import UIKit
import Interstellar
import Forgeries

@testable
import Artsy

class LiveAuctionViewControllerTests: QuickSpec {


    override func spec() {
        var subject: LiveAuctionViewController!

        func setupViewControllerForPhone(singleLayout: Bool) {

            subject = LiveAuctionViewController(saleSlugOrID: "sale-id")
            subject.staticDataFetcher = Stubbed_StaticDataFetcher()
            subject.useSingleLayout = singleLayout
        }

        beforeEach {
            OHHTTPStubs.stubJSONResponseAtPath("/api/v1/sale/los-angeles-modern-auctions-march-2015", withResponse:[:])

            let fake = stub_auctionSalesPerson()
            for i in 0..<fake.lotCount {
                let lot = fake.lotViewModelForIndex(i)
                cacheColoredImageForURL(lot.urlForThumbnail)
            }
        }

        it("looks good by default") {
            setupViewControllerForPhone(true)
            expect(subject).to (haveValidSnapshot(named: nil, usesDrawRect: true))
        }

        it("handles splitting in an iPad") {
            setupViewControllerForPhone(false)
            subject.stubHorizontalSizeClass(.Regular)
            subject.view.frame = CGRect(x: 0, y: 0, width: 1024, height: 768)

            expect(subject).to (haveValidSnapshot(named: nil, usesDrawRect: true))
        }

        it("shows an error screen when static data fails") {
            setupViewControllerForPhone(true)

            let fakeStatic = FakeStaticFetcher()
            subject.staticDataFetcher = fakeStatic

            subject.beginAppearanceTransition(true, animated: false)
            subject.view.frame = CGRect(x: 0, y: 0, width: 320, height: 480)
            subject.endAppearanceTransition()

            let result: StaticSaleResult = Result.Error(LiveAuctionStaticDataFetcher.Error.JSONParsing)
            fakeStatic.fakeObserver.update(result)

            expect(subject).to (haveValidSnapshot(named: nil, usesDrawRect: true))
        }

        it("shows a socket disconnect screen when socket fails") {
            setupViewControllerForPhone(true)
            let fakeSalesPerson = stub_auctionSalesPerson()
            subject.salesPersonCreator = { _ in
                return fakeSalesPerson
            }

            fakeSalesPerson.socketConnectionSignal.update(false)
            expect(subject).to (haveValidSnapshot(named: nil, usesDrawRect: true))
        }

        it("shows a removes disconnected screen when socket reconnects") {
            setupViewControllerForPhone(true)
            let fakeSalesPerson = stub_auctionSalesPerson()
            subject.salesPersonCreator = { _ in
                return fakeSalesPerson
            }

            fakeSalesPerson.socketConnectionSignal.update(false)
            // Adds everything synchronously, which is the test above
            fakeSalesPerson.socketConnectionSignal.update(true)
            expect(subject).to (haveValidSnapshot(named: nil, usesDrawRect: true))
        }



        it("shows an operator disconnect screen when operator disconnects") {
            setupViewControllerForPhone(true)
            let fakeSalesPerson = stub_auctionSalesPerson()
            subject.salesPersonCreator = { _ in
                return fakeSalesPerson
            }

            fakeSalesPerson.operatorConnectedSignal.update(false)
            expect(subject).to (haveValidSnapshot(named: nil, usesDrawRect: true))
        }

        it("shows an operator disconnected screen when operator reconnects") {
            setupViewControllerForPhone(true)
            let fakeSalesPerson = stub_auctionSalesPerson()
            subject.salesPersonCreator = { _ in
                return fakeSalesPerson
            }

            fakeSalesPerson.operatorConnectedSignal.update(false)
            // Adds everything synchronously, which is the test above
            fakeSalesPerson.operatorConnectedSignal.update(true)
            expect(subject).to (haveValidSnapshot(named: nil, usesDrawRect: true))
        }
    }
}

class FakeStaticFetcher: LiveAuctionStaticDataFetcherType {
    let fakeObserver = Observable<StaticSaleResult>()
    func fetchStaticData() -> Observable<StaticSaleResult> {
        return fakeObserver
    }
}
