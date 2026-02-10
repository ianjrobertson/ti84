import Foundation

/// All built-in functions available on the TI-84 Plus.
public enum BuiltinFunction: String, CaseIterable, Sendable {
    // Trig
    case sin, cos, tan
    case asin, acos, atan
    case sinh, cosh, tanh
    case asinh, acosh, atanh

    // Powers and roots
    case sqrt
    case cbrt       // ³√( — via MATH menu
    case xRoot      // ˣ√ — via MATH menu

    // Exponential/Log
    case log
    case ln
    case tenPow     // 10^(
    case ePow       // e^(

    // Numeric
    case abs
    case round
    case iPart
    case fPart
    case int_       // int( — floor toward negative inf
    case min
    case max
    case lcm
    case gcd

    // Angle/DMS
    case degrees    // ►DMS
    case angle      // angle(

    // Complex
    case real
    case imag
    case conj
    case cAbs = "abs_complex"

    // Probability
    case nPr
    case nCr
    case factorial
    case rand
    case randInt
    case randNorm
    case randBin

    // List operations
    case dim
    case seq
    case cumSum
    case deltaList  // ΔList(
    case sortA
    case sortD
    case augment
    case sum
    case prod
    case mean
    case median
    case stdDev
    case variance

    // Matrix operations
    case det
    case identity
    case fill
    case ref
    case rref
    case rowSwap
    case rowPlus    // row+(
    case mRow       // *row(
    case mRowPlus   // *row+(
    case transpose  // ᵀ
    case randM

    // String operations
    case length
    case sub        // sub(
    case inString
    case expr

    // Statistics
    case linReg     // LinReg(ax+b)
    case quadReg
    case cubicReg
    case quartReg
    case expReg
    case lnReg
    case pwrReg
    case sinReg
    case logistic
    case linRegTTest
    case medMed

    // Distribution functions
    case normalPdf
    case normalCdf
    case invNorm
    case tPdf
    case tCdf
    case invT
    case chiSquaredPdf = "chi2Pdf"
    case chiSquaredCdf = "chi2Cdf"
    case fPdf
    case fCdf
    case binomPdf
    case binomCdf
    case poissonPdf
    case poissonCdf
    case geometPdf
    case geometCdf

    // Graph/Calc
    case fnInt      // fnInt( — numerical integration
    case nDeriv     // nDeriv( — numerical derivative
    case fMin
    case fMax
    case solve      // solve( — equation solver

    // Conversion
    case toString   // toString(
    case eval       // eval(

    /// Display name as it appears on the TI-84 screen
    public var displayName: String {
        switch self {
        case .sin: return "sin("
        case .cos: return "cos("
        case .tan: return "tan("
        case .asin: return "sin⁻¹("
        case .acos: return "cos⁻¹("
        case .atan: return "tan⁻¹("
        case .sinh: return "sinh("
        case .cosh: return "cosh("
        case .tanh: return "tanh("
        case .asinh: return "sinh⁻¹("
        case .acosh: return "cosh⁻¹("
        case .atanh: return "tanh⁻¹("
        case .sqrt: return "√("
        case .cbrt: return "³√("
        case .xRoot: return "ˣ√"
        case .log: return "log("
        case .ln: return "ln("
        case .tenPow: return "10^("
        case .ePow: return "e^("
        case .abs: return "abs("
        case .round: return "round("
        case .iPart: return "iPart("
        case .fPart: return "fPart("
        case .int_: return "int("
        case .min: return "min("
        case .max: return "max("
        case .lcm: return "lcm("
        case .gcd: return "gcd("
        case .nPr: return "nPr"
        case .nCr: return "nCr"
        case .factorial: return "!"
        case .rand: return "rand"
        case .randInt: return "randInt("
        case .randNorm: return "randNorm("
        case .randBin: return "randBin("
        case .dim: return "dim("
        case .seq: return "seq("
        case .cumSum: return "cumSum("
        case .deltaList: return "ΔList("
        case .sortA: return "SortA("
        case .sortD: return "SortD("
        case .augment: return "augment("
        case .sum: return "sum("
        case .prod: return "prod("
        case .mean: return "mean("
        case .median: return "median("
        case .stdDev: return "stdDev("
        case .variance: return "variance("
        case .det: return "det("
        case .identity: return "identity("
        case .fill: return "Fill("
        case .ref: return "ref("
        case .rref: return "rref("
        case .rowSwap: return "rowSwap("
        case .rowPlus: return "row+("
        case .mRow: return "*row("
        case .mRowPlus: return "*row+("
        case .transpose: return "ᵀ"
        case .randM: return "randM("
        case .length: return "length("
        case .sub: return "sub("
        case .inString: return "inString("
        case .expr: return "expr("
        case .fnInt: return "fnInt("
        case .nDeriv: return "nDeriv("
        case .fMin: return "fMin("
        case .fMax: return "fMax("
        case .solve: return "solve("
        case .normalPdf: return "normalPdf("
        case .normalCdf: return "normalCdf("
        case .invNorm: return "invNorm("
        case .tPdf: return "tPdf("
        case .tCdf: return "tCdf("
        case .invT: return "invT("
        case .chiSquaredPdf: return "χ²pdf("
        case .chiSquaredCdf: return "χ²cdf("
        case .fPdf: return "Fpdf("
        case .fCdf: return "Fcdf("
        case .binomPdf: return "binompdf("
        case .binomCdf: return "binomcdf("
        case .poissonPdf: return "poissonpdf("
        case .poissonCdf: return "poissoncdf("
        case .geometPdf: return "geometpdf("
        case .geometCdf: return "geometcdf("
        case .real: return "real("
        case .imag: return "imag("
        case .conj: return "conj("
        case .cAbs: return "abs("
        case .degrees: return "►DMS"
        case .angle: return "angle("
        case .linReg: return "LinReg(ax+b)"
        case .quadReg: return "QuadReg"
        case .cubicReg: return "CubicReg"
        case .quartReg: return "QuartReg"
        case .expReg: return "ExpReg"
        case .lnReg: return "LnReg"
        case .pwrReg: return "PwrReg"
        case .sinReg: return "SinReg"
        case .logistic: return "Logistic"
        case .linRegTTest: return "LinRegTTest"
        case .medMed: return "Med-Med"
        case .toString: return "toString("
        case .eval: return "eval("
        }
    }
}
