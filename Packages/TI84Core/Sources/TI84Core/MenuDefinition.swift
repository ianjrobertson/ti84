import Foundation

/// Definition of a calculator menu (MATH, STAT, etc.)
public struct MenuDefinition: Equatable, Sendable {
    public let title: String
    public let tabs: [MenuTab]

    public init(title: String, tabs: [MenuTab]) {
        self.title = title
        self.tabs = tabs
    }
}

public struct MenuTab: Equatable, Sendable {
    public let name: String
    public let items: [MenuItem]

    public init(name: String, items: [MenuItem]) {
        self.name = name
        self.items = items
    }
}

public struct MenuItem: Equatable, Sendable, Identifiable {
    public let id: String
    public let label: String
    public let insertText: String

    public init(id: String, label: String, insertText: String) {
        self.id = id
        self.label = label
        self.insertText = insertText
    }
}

// MARK: - Standard TI-84 Menus

public enum StandardMenus {
    public static let math = MenuDefinition(
        title: "MATH",
        tabs: [
            MenuTab(name: "MATH", items: [
                MenuItem(id: "frac", label: "►Frac", insertText: "►Frac"),
                MenuItem(id: "dec", label: "►Dec", insertText: "►Dec"),
                MenuItem(id: "cbrt", label: "³√(", insertText: "³√("),
                MenuItem(id: "xroot", label: "ˣ√", insertText: "ˣ√"),
                MenuItem(id: "fmin", label: "fMin(", insertText: "fMin("),
                MenuItem(id: "fmax", label: "fMax(", insertText: "fMax("),
                MenuItem(id: "nderiv", label: "nDeriv(", insertText: "nDeriv("),
                MenuItem(id: "fnint", label: "fnInt(", insertText: "fnInt("),
                MenuItem(id: "solve", label: "solve(", insertText: "solve("),
            ]),
            MenuTab(name: "NUM", items: [
                MenuItem(id: "abs", label: "abs(", insertText: "abs("),
                MenuItem(id: "round", label: "round(", insertText: "round("),
                MenuItem(id: "ipart", label: "iPart(", insertText: "iPart("),
                MenuItem(id: "fpart", label: "fPart(", insertText: "fPart("),
                MenuItem(id: "int", label: "int(", insertText: "int("),
                MenuItem(id: "min", label: "min(", insertText: "min("),
                MenuItem(id: "max", label: "max(", insertText: "max("),
                MenuItem(id: "lcm", label: "lcm(", insertText: "lcm("),
                MenuItem(id: "gcd", label: "gcd(", insertText: "gcd("),
            ]),
            MenuTab(name: "CPX", items: [
                MenuItem(id: "conj", label: "conj(", insertText: "conj("),
                MenuItem(id: "real", label: "real(", insertText: "real("),
                MenuItem(id: "imag", label: "imag(", insertText: "imag("),
                MenuItem(id: "angle", label: "angle(", insertText: "angle("),
                MenuItem(id: "absC", label: "abs(", insertText: "abs("),
            ]),
            MenuTab(name: "PRB", items: [
                MenuItem(id: "nPr", label: "nPr", insertText: "nPr"),
                MenuItem(id: "nCr", label: "nCr", insertText: "nCr"),
                MenuItem(id: "fact", label: "!", insertText: "!"),
                MenuItem(id: "rand", label: "rand", insertText: "rand"),
                MenuItem(id: "randint", label: "randInt(", insertText: "randInt("),
                MenuItem(id: "randnorm", label: "randNorm(", insertText: "randNorm("),
                MenuItem(id: "randbin", label: "randBin(", insertText: "randBin("),
            ]),
        ]
    )

    public static let stat = MenuDefinition(
        title: "STAT",
        tabs: [
            MenuTab(name: "EDIT", items: [
                MenuItem(id: "edit", label: "Edit...", insertText: ""),
                MenuItem(id: "sorta", label: "SortA(", insertText: "SortA("),
                MenuItem(id: "sortd", label: "SortD(", insertText: "SortD("),
                MenuItem(id: "clrlist", label: "ClrList", insertText: "ClrList "),
                MenuItem(id: "setupeditor", label: "SetUpEditor", insertText: "SetUpEditor "),
            ]),
            MenuTab(name: "CALC", items: [
                MenuItem(id: "1var", label: "1-Var Stats", insertText: "1-Var Stats "),
                MenuItem(id: "2var", label: "2-Var Stats", insertText: "2-Var Stats "),
                MenuItem(id: "medmed", label: "Med-Med", insertText: "Med-Med "),
                MenuItem(id: "linreg", label: "LinReg(ax+b)", insertText: "LinReg(ax+b) "),
                MenuItem(id: "quadreg", label: "QuadReg", insertText: "QuadReg "),
                MenuItem(id: "cubicreg", label: "CubicReg", insertText: "CubicReg "),
                MenuItem(id: "quartreg", label: "QuartReg", insertText: "QuartReg "),
                MenuItem(id: "linregttest", label: "LinRegTTest", insertText: "LinRegTTest "),
                MenuItem(id: "expreg", label: "ExpReg", insertText: "ExpReg "),
                MenuItem(id: "lnreg", label: "LnReg", insertText: "LnReg "),
                MenuItem(id: "pwrreg", label: "PwrReg", insertText: "PwrReg "),
                MenuItem(id: "logistic", label: "Logistic", insertText: "Logistic "),
                MenuItem(id: "sinreg", label: "SinReg", insertText: "SinReg "),
            ]),
            MenuTab(name: "TESTS", items: [
                MenuItem(id: "ztest", label: "Z-Test(", insertText: "Z-Test("),
                MenuItem(id: "ttest", label: "T-Test(", insertText: "T-Test("),
                MenuItem(id: "2sampztest", label: "2-SampZTest(", insertText: "2-SampZTest("),
                MenuItem(id: "2sampttest", label: "2-SampTTest(", insertText: "2-SampTTest("),
            ]),
        ]
    )
}
