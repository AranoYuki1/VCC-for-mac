//
//  TemplateView+.swift
//  VCCMac
//
//  Created by yuki on 2022/12/26.
//

import CoreUtil

final class __ComponentsViewController: NSViewController {
    private let cell = ComponentsView()
    
    override func loadView() { self.view = cell }
    
    override func chainObjectDidLoad() {
        
    }
}

final private class ComponentsView: Page {
    override func onAwake() {
        
        
        
        self.addSection(H1Title(text: "H1 Title"))
        self.addSection(H2Title(text: "H2 Title"))
        self.addSection(H3Title(text: "H3 Title"))
        self.addSection(H4Title(text: "H4 Title"))
        self.addSection(H5Title(text: "H5 Title"))
        self.addSection(H6Title(text: "H6 Title"))
        self.addSection(Paragraph(text: """
        This is a Paragraph. Dolore duis voluptate dolore incididunt est ex sint nulla voluptate nisi eiusmod adipiscing ex veniam irure esse nostrud laborum amet aute labore adipiscing qui anim nostrud reprehenderit do laborum magna aliquip ipsum amet nostrud adipiscing ad culpa nulla ea et esse magna sunt non eu dolore excepteur sed non.
        """))
        
        self.addSection(NoteView(type: .info))
        self.addSection(NoteView(type: .warn) => {
            $0.message = "This is a Paragraph. Dolore duis voluptate dolore incididunt est ex sint nulla voluptate nisi eiusmod adipiscing ex veniam irure esse nostrud laborum amet aute labore adipiscing qui anim nostrud reprehenderit do laborum magna aliquip ipsum amet nostrud adipiscing ad culpa nulla ea et esse magna sunt non eu dolore excepteur sed non"
        })
        self.addSection(NoteView(type: .alert))
               
        self.addSection(
            Area(
                icon: R.image.export(),
                title: "Area",
                message: "This is area message",
                control: Button(title: "Show Toast") => {
                    $0.actionPublisher.sink{ Toast(message: "This is a Toast notification").show() }.store(in: &objectBag)
                }
            )
        )
        
        self.addSection2(
            Area(
                icon: R.image.export(),
                title: "Area",
                message: "This is area message",
                control: Button(title: "Warn Toast") => {
                    $0.actionPublisher.sink{ Toast(message: "This is a Toast notification", color: .systemOrange).show() }.store(in: &objectBag)
                    $0.backgroundColor = .systemOrange
                }
            ),
            Area(
                icon: R.image.export(),
                title: "Area",
                message: "This is area message",
                control: Button(title: "Error Toast") => {
                    $0.actionPublisher.sink{ Toast(message: "This is a Toast notification", color: .systemRed).show() }.store(in: &objectBag)
                    $0.backgroundColor = .systemRed
                }
            )
        )
        
        enum PopupItem: String, TextItem {
            case item1 = "Popup Item 1"
            case item2 = "Popup Item 2"
            case item3 = "Popup Item 3"
        }
        
        self.addSection(
            Area(
                icon: R.image.export(),
                title: "Popup Area",
                message: "This is area message",
                control: EnumPopupButton<PopupItem>() => { button in
                    button.itemPublisher.sink{ button.selectedItem = $0 }.store(in: &objectBag)
                    button.selectedItem = .item1
                }
            )
        )
        
        self.addSection(Section(title: "Section with TextField", items: [
            TextField()
        ], toolbarItems: [
            SectionButton(title: "Section Button", image: R.image.search()),
            SectionButton(image: R.image.paramators())
        ]))
        
        self.addSection(Section(title: "Section with DatePicker", items: [
            DatePicker()
        ]))
        
        self.addSection(FileDropSection() => {
            $0.title = "Section with FileDrop"
        })
        
        self.addSection(Section(title: "Section with TagCloud", items: [
            TagCloudView() => {
                $0.items = (0...10).map{ "Tag Item \($0)" }
            }
        ]))
    }
}

