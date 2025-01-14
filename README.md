<div align="center">
    <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/MIT_GNU_Scheme_Logo.svg/1200px-MIT_GNU_Scheme_Logo.svg.png" width="120" alt="MIT/GNU Scheme Logo"/>
</div>

<h1 align="center">
    A REPL Interpreter for Scheme
</h1>

<div align="center">

[![PL](https://img.shields.io/badge/MIT%2FGNU_Scheme-red?style=for-the-badge)](https://www.gnu.org/software/mit-scheme/)
[![Status](https://img.shields.io/badge/status-completed-green?style=for-the-badge)]()
[![License](https://img.shields.io/badge/license-MIT-red?style=for-the-badge)](https://github.com/Kj0ric/lcd-semantic-analyzer/blob/main/LICENSE)

</div>

A limited REPL (Read-Eval-Print Loop) interpreter for a subset of MIT Scheme, implemented in Scheme itself. This interpreter handles basic arithmetic operations, variable definitions, let expressions, and lambda functions.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Supported Syntax](#supported-syntax)
- [Usage](#usage)
- [Example Interactions](#example-interactions)
- [Implementation Details](#implementation-details)
- [Error Handling](#error-handling)
- [Limitations](#limitations)
- [License](#license)
- [Acknowledgement](#acknowledgement)

## Features

- REPL environment with proper prompt handling
- Support for basic arithmetic operations (+, -, *, /)
- Variable definitions using `define`
- Local variable bindings using `let` expressions
- Lambda expressions and function applications
- Error handling and validation
- Dynamic scoping for variable resolution

## Installation

### Prerequisites

1. **MIT Scheme**
   - **Linux (Debian/Ubuntu)**:
     ```bash
     sudo apt-get update
     sudo apt-get install mit-scheme
     ```
   - **macOS** (using Homebrew):
     ```bash
     brew install mit-scheme
     ```
   - **Windows**:
     1. Download the installer from [MIT Scheme's official website](https://www.gnu.org/software/mit-scheme/)
     2. Run the installer and follow the installation wizard
     3. Add MIT Scheme to your system's PATH environment variable

2. **Verify Installation**:
   ```bash
   scheme --version
   ```

### Setting Up the Project

1. Clone the repository:
   ```bash
   git clone [repository-url]
   cd s7-scheme-interpreter
   ```

2. Test the interpreter:
   ```bash
   mit-scheme --load interpreter.scm
   ```

## Supported Syntax

The interpreter supports the following grammar:

```bnf
<s7> ::= <define> 
       | <expr>

<define> ::= (define IDENT <expr>)

<expr> ::= NUMBER 
         | IDENT 
         | <let> 
         | <lambda> 
         | (<operator> <operand_list>)

<let> ::= (let (<var_binding_list>) <expr>)

<lambda> ::= (lambda (<formal_list>) <expr>)

<operator> ::= <built_in_operator> 
             | <expr>

<built_in_operator> ::= + 
                      | * 
                      | - 
                      | /
```

## Usage

1. Load the interpreter in your Scheme environment:
```scheme
(load "interpreter.scm")
```

2. Start the REPL:
```scheme
(repl)
```

3. Enter expressions at the prompt:
```scheme
repl> (define x 5)
repl: x
repl> (+ x 3)
repl: 8
```

## Example Interactions

```scheme
repl> ((lambda (n) (+ n 2)) 5)
repl: 7

repl> (define inc2 (lambda (n) (+ n 2)))
repl: inc2
repl> (inc2 5)
repl: 7

repl> (let ((x 3)(y 4)) (+ x y))
repl: 7
```

## Implementation Details

### Core Components

1. **REPL (Read-Eval-Print Loop)**
   - Implemented in the `repl` function
   - Maintains an environment for variable bindings
   - Handles both definitions and expressions
   - Provides appropriate prompts and error messages

2. **Environment Management**
   - Environment implemented as an association list of (variable . value) pairs
   - Supports variable lookup with proper scoping rules
   - Dynamic environment updates for define statements
   - Temporary environment creation for let expressions

3. **Expression Evaluation**
   - Recursive evaluation of nested expressions
   - Special handling for different expression types:
     - Numbers evaluate to themselves
     - Identifiers are looked up in the environment
     - Let expressions create new scope
     - Lambda expressions create closures
     - Applications handle both built-in and user-defined procedures

4. **Error Handling**
   - Syntax validation for all expression types
   - Runtime error detection
   - Proper error recovery and REPL continuation

### Key Implementation Features

1. **Closure Implementation**
   - Closures capture:
     - Parameter list
     - Body expression
     - Definition environment
   - Proper environment preservation for later execution

2. **Let Expression Handling**
   - Duplicate variable detection
   - Sequential evaluation of bindings
   - Creation of new scope for expression evaluation

3. **Arithmetic Operations**
   - Left-associative evaluation
   - Support for variable number of operands (2 or more)
   - Proper operator precedence

## Error Handling

The interpreter provides error messages for:
- Undefined variables
- Invalid syntax
- Duplicate variable bindings in let expressions
- Argument count mismatches in function applications
- Invalid identifiers in define statements

## Limitations

- Only handles binary or more operands for arithmetic operations
- No support for boolean operations or control structures
- Limited to a subset of Scheme syntax
- No support for recursive definitions

## License

This project is licensed under the MIT License - see the [LICENSE](/LICENSE) file for details.

## Acknowledgements

This project was developed as part of the Programming Languages course at Sabanci University. Special thanks to the course instructor Hüsnü Yenigün and teaching assistants for their guidance and support.
