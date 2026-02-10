# TI-84 Plus Calculator — macOS App

A native macOS app that recreates the TI-84 Plus calculator experience using SwiftUI. This is a from-scratch visual calculator (not a hardware emulator) covering scientific calculation, graphing, matrices, lists, statistics, and TI-BASIC programming.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)

## Building & Running

Requires Swift 5.9+ (Xcode Command Line Tools or full Xcode).

```bash
cd /path/to/ti84
swift build
open .build/debug/TI84App
```

Or open `TI84App/TI84App.xcodeproj` in Xcode and hit Run.

## Usage

### Home Screen (Basic Calculator)

Type expressions using the on-screen keypad or your keyboard and press **ENTER** to evaluate.

**Keyboard shortcuts:**
| Key | Action |
|-----|--------|
| `0`–`9`, `.` | Digits |
| `+` `-` `*` `/` `^` | Operators |
| `(` `)` | Parentheses |
| Enter | Evaluate |
| Escape | Clear |
| Backspace | Delete |
| Arrow keys | Move cursor |

**Examples to try:**
- `2+3*4` → `14`
- `-3^2` → `-9` (negation has lower precedence than exponent, matching TI-84 behavior)
- `sin(3.14159/6)` → `~0.5`
- `6/2(1+2)` → `9` (implicit multiplication)
- `5!` → `120`
- `10nCr3` → `120`

### Graphing

1. Click **Y=** on the keypad
2. Type an equation in any Y slot (e.g. `sin(X)`, `X^2-4`, `cos(2*X)`)
3. Click **GRAPH** to plot

**Graph controls:**
- **TRACE** — move a cursor along the function with left/right arrows, switch functions with up/down
- **ZOOM** — access zoom presets (ZStandard, ZTrig, ZDecimal, ZSquare, etc.)
- **WINDOW** — manually set Xmin, Xmax, Ymin, Ymax, scale, and resolution

### Tables

Press **2nd** then **GRAPH** (or navigate to Table) to see a table of X/Y values for your enabled equations.

### Menus

- **MATH** — math functions (abs, round, iPart, fPart, min, max, gcd, lcm, nDeriv, fnInt, etc.) plus NUM, CPX, and PRB submenus
- **STAT** — statistics (Edit lists, 1-Var/2-Var Stats, regressions)
- **MODE** — switch between Radian/Degree, Normal/Sci/Eng, Float/Fixed, graph modes

Navigate menus with arrow keys or press a number key for quick selection.

### Other Features

- **Matrix editor** — edit matrices [A]–[J], supports inverse, determinant, ref, rref, row operations
- **List editor** — edit lists L1–L6, supports sum, mean, median, cumSum, seq, sort, augment
- **Variables** — store values with `→` (e.g. `42→X`)
- **2nd / ALPHA** — modifier keys for secondary functions and letter input
- **Program editor** — write and run TI-BASIC programs

## Architecture

```
SwiftUI Views → ViewModels → AppState → TI84Engine (Swift Package)
                                              ├── ExpressionParser (Tokenizer + Pratt Parser → AST)
                                              ├── Evaluator (AST → TI84Value)
                                              ├── GraphEngine (Plotting, Trace, Zoom, Calculate)
                                              ├── MathKernel (Matrix ops, Stats, Complex math)
                                              ├── CalculatorState (Variables, memory, settings)
                                              └── TIBasicInterpreter (Parser + async executor)
```

**MVVM with centralized state + modular engine in local Swift packages.**

| Package | Purpose |
|---------|---------|
| `TI84Core` | Shared types (Token, ASTNode, TI84Value, CalcKey, etc.) — no dependencies |
| `TI84Engine` | All computation — parser, evaluator, graph engine, math kernel, TI-BASIC interpreter |
| `TI84App` | SwiftUI macOS app — views, view models, key dispatch |

### Key Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Parser | Pratt (precedence-climbing) | Cleanly handles 9 precedence levels, right-associative `^`, prefix functions, postfix operators |
| Graph rendering | SwiftUI `Canvas` | Imperative drawing, efficient for thousands of line segments |
| Value type | `TI84Value` enum (real, complex, list, matrix, string) | Universal type throughout the engine |
| Implicit multiplication | Tokenizer inserts explicit tokens | Keeps parser simple; handles `2sin(X)`, `3(4)`, `2π` correctly |
| Negation vs subtraction | Tokenizer disambiguates by context | `(-)` after operator/lparen/start = negation; after number/rparen = subtraction |
| TI-BASIC execution | Flat indexed statement list | Supports Goto/Lbl jumping in/out of loops |
| TI-BASIC concurrency | Swift `async/await` + actors | UI stays responsive; Input/getKey suspend; ON key cancels |

## Project Structure

```
ti84/
├── Package.swift                          # Top-level build (swift build)
├── Packages/
│   ├── TI84Core/                          # Shared types
│   │   └── Sources/TI84Core/
│   │       ├── TI84Value.swift            # Universal value enum
│   │       ├── Token.swift, ASTNode.swift # Parser types
│   │       ├── CalcKey.swift              # All physical keys
│   │       ├── CalcError.swift            # TI-84 error types
│   │       ├── BuiltinFunction.swift      # All built-in functions
│   │       ├── Operator.swift             # Precedence and associativity
│   │       ├── ModeSettings.swift         # Calculator mode settings
│   │       ├── WindowParameters.swift     # Graph window parameters
│   │       └── MenuDefinition.swift       # Menu structures
│   └── TI84Engine/                        # Computation engine
│       └── Sources/
│           ├── ExpressionParser/          # Tokenizer + Pratt parser
│           ├── Evaluator/                 # AST evaluator + number formatter
│           ├── CalculatorState/           # Variables, lists, matrices, persistence
│           ├── GraphEngine/               # Plotter, trace, zoom, root/extremum finders
│           ├── MathKernel/                # Matrix ops, statistics, complex math
│           └── TIBasicInterpreter/        # Parser + async executor
└── TI84App/
    ├── TI84App.xcodeproj/                 # Xcode project (alternative to swift build)
    └── TI84App/
        ├── TI84App.swift                  # @main App entry
        ├── App/                           # AppState, KeyDispatcher, KeyboardShortcuts
        ├── Views/
        │   ├── CalculatorShell.swift      # Main window layout
        │   ├── Display/                   # All screen views (Home, Graph, Table, Y=, etc.)
        │   ├── Keypad/                    # Button grid, button styles, key definitions
        │   └── Components/                # StatusBar, LCD text, cursor
        └── ViewModels/                    # Home, Graph, Table, Menu view models
```
