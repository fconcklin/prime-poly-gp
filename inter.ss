#|
schush.ss: This file implements:
           - Schush, a version of the Push programming language for evolutionary
             computation, and 
           - SchushGP, a version of the PushGP genetic programming system,
           implemented in PLT Scheme (http://www.plt-scheme.org/).

Copyright (c) 2009, 2010 Lee Spector (lspector@hampshire.edu)
See version history at the bottom of this comment.

This program is free software: you can redistribute it and/or modify it under
the terms of version 3 of the GNU General Public License as published by the
Free Software Foundation, available from http://www.gnu.org/licenses/gpl.txt.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License (http://www.gnu.org/licenses/)
for more details.

REQUIREMENTS

This code was developed in PLT Scheme (http://www.plt-scheme.org/), using the 
DrScheme development environment. It will probably work with minor patches in
other versions of Scheme, although I haven't tried that. A few things that I
would expect to require attention for a port are the graph-plotting code
(which you might just want to remove), the namespace declaration (required 
in PLT Scheme to get eval to work correctly), and in-range.

QUICK START

Run this file unmodified in PLT Scheme to conduct an example run of the PushGP
genetic programming system on one of the demo problems (whichever one was left
uncommented at the bottom of this file when it was released).

PLT Scheme can be downloaded from http://www.plt-scheme.org/, and you can run
SchushGP either within PLT's DrScheme programming environment or by using PLT's
mzscheme command-line program (using the command: "mzscheme schush.ss"). Graphical
output will appear only if graphics are available in your environment (e.g. in
DrScheme), but the program will run correctly without the graphics, and 
textual output is always provided. If you are using DrScheme and it asks you
to "choose a language" you should choose "Module" (which is the full PLT
Scheme language).

DESCRIPTION

Schush is a version of the Push programming language for evolutionary 
computation, implemented in Scheme. SchushGP is a version of the PushGP
genetic programming system built on top of Schush. More information about
Push and PushGP can be found at http://hampshire.edu/lspector/push.html.

Schush derives mainly from Push3 
(http://hampshire.edu/lspector/push3-description.html,
http://hampshire.edu/lspector/pubs/push3-gecco2005.pdf) but it is not
intended to be fully compliant with the Push3 standard and there are a few
intentional differences.

If you want to understand the motivations for the development of Push, and 
the variety of things that it can be used for, you should read a selection of
the documents listed at http://hampshire.edu/lspector/push.html, probably
starting with the 2002 Genetic Programming and Evolvable Machines article
that can be found at http://hampshire.edu/lspector/pubs/push-gpem-final.pdf.
But bear in mind that Push has changed over the years, and that Schush is
closest to Push3 (references above).

Push/Schush can be used as the foundation of many evolutionary algorithms, 
not only PushGP/SchushGP (which is more or less a standard GP system except
that it evolves Push/Schush programs rather than Lisp-style function trees --
which can make a big difference!). It was developed primarily for
"meta-genetic-programming" or "autoconstructive evolution" experiments, in
which programs and genetic operators co-evolve or in which programs produce
their own offspring while also solving problems. But it turns out that
Push/Schush has a variety of uniquely nice features even within a more
traditional genetic programming context; for example it makes it unusually
easy to evolve programs that use multiple data types, it provides novel and
automatic forms of program modularization and control structure co-evolution,
and it allows for a particularly simple form of automatic program
simplification. The code in this file implements a Push/Schush interpreter
and a PushGP/SchushGP genetic programming system; it can serve as the
foundation for other evolutionary algorithms, but only the core Push/Schush
interpreter and a version of PushGP/SchushGP are provided here. The version
of PushGP/SchushGP provided here is relatively straightforward, although a few
slightly fancy enhancements such as "trivial geography" and error scaling
by "historically assessed hardness" have been included (see the version 
history below for details and references).

USAGE

Running this file as distributed should load everything, print the list of 
registered Schush instructions, and run SchushGP on an example problem. To do
other things you should first comment out the currently uncommented SchushGP
example (near the end of the file). You could then try other examples (by 
uncommenting them) or add your code (either for SchushGP runs or other uses
of Schush) at the end of the file, or you could include this code in
another project (but as of this writing I have not added the module
declarations that would facilitate doing this in the proper PLT style).

Schush programs are run calling run-schush, which takes as arguments a schush 
program and a schush interpreter state that can be made with
make-schush-state. If you are planning to use SchushGP then you will want to
use this in the error function (a.k.a. fitness function) that you pass to the
schushgp function. Here is a simple example of a call to run-schush, adding 1
and 2 and returning the top of the integer stack in the resulting interpreter
state:

(let ((s (make-schush-state)))
  (run-schush '(1 2 integer.+) s)
  (top 'integer s))

To try this paste it below all of the code in this file (after commenting out
the currently uncommented schushgp example) and run the file, or in DrScheme
you could instead run the file as-is and then past this into the interaction
pane and hit "return".

If you want to see every step of execution you can pass an optional third
argument of #t to run-schush. This will cause a representation of the
interpreter state to be printed at the start of execution and after
each step. Here is the same example as above but with each step printed:

(let ((s (make-schush-state)))
  (run-schush '(1 2 integer.+) s #t)
  (top 'integer s))

See the "parameters" section of the code for some parameters that will affect 
execution, e.g. whether code is pushed onto and/or popped off of the code
stack prior to/after execution, along with the evaluation limit (which can be
necessary for halting otherwise-infinite loops, etc.).

Run-schush destructively modifies the interpreter state that it is given, and
returns a value indicating if execution terminated normally (#t) or if it was
aborted because the evaluation limit was reached (#f).

Random code can be generated with random-code, which takes a size limit and a 
list of "atom generators." Size is calculated in "points" -- each atom and
each pair of parentheses counts as a single point. Each atom-generator should
be a constant, or the name of a Schush instruction (in which case it will be
used literally), or a Scheme procedure that will be called with no arguments
to produce a constant or a Schush instruction. This is how "ephemeral random
constants" can be incorporated into evolutionary systems that use schush --
that is, it is how you can cause random constants to appear in
randomly-generated programs without including all possible constants in the
list of elements out of which programs can be constructed. Here is an example
in which a random program is generated, printed, and run. It prints a message
indicating whether or not the program terminated normally (which it may not,
since it may be a large and/or looping program, and since the default
evaluation limit is pretty low) and it prints the internal representation of
the resulting interpreter state:


(let ((s (make-schush-state))
      (c (random-code 
          100                                     ;; use a size limit of 100 points
          (append registered-instructions         ;; all registered instructions can be included
                  (list (lambda () (random 100))  ;; this can generate random integers from 0-99
                        (lambda () (random))))))) ;; this, random floats from 0.0-1.0
  (printf "~nCode: ~a~n" c)
  (printf "~nTerminated normally?: ~A~n" (run-schush c s))
  (printf "~nResulting interpreter state: ~A~n" s)
  (void)) ;; return nothing

If you look carefully at the resulting interpreter state you may notice an 
"auxiliary" stack that is not mentioned in any of the Push publications. This
exists to allow for auxiliary information to be passed to programs without
using global variables; in particular, it is used for the "input instructions"
in some of the SchushGP examples below. One often passes data to a Push
program by pushing it onto the appropriate stacks before running the program,
but in many cases it can also be helpful to have an instruction that
re-pushes the input whenever it is needed. The auxiliary stack is just a
convenient place to store the values so that they can be grabbed by input
instructions and pushed onto the appropriate stacks when needed. Perhaps
you will find other uses for it as well, but no instructions are provided
for the auxiliary stack in this file (aside from the problem-specific input
functions in the examples).

The schushgp function is used to run SchushGP. It takes many arguments, most 
of which are specified with keywords and have default values. Search below
for "define schushgp" to find the definition and see details. The single
argument that must be provided is error-function, which should take a program
and return a list of errors. Note that this assumes that you will be doing
single-objective optimization with the objective being thought of as an error
to be minimized. This assumption not intrinsic to Push/Schush or
PushGP/SchushGP; it's just the simplest and most standard thing to do, so
it's what I've done here. One could easily hack around that. In the most
generic applications you'll want to have your error function run through a
list of inputs, set up the interpreter and call run-schush for each,
calculate an error for each (potentially with penalties for abnormal
termination, etc.), and return a list of the errors.

Not all of the default arguments to schushgp will be reasonable for all 
problems. In particular, the default list of atom-generators -- which is ALL
registered instructions, a random integer generator (in the range from 0-99)
and a random float generator (in the range from 0.0 to 1.0) -- will be
overkill for many problems and is so large that it may make otherwise simple
problems quite difficult because the chances of getting the few needed
instructions together into the same program will be quite low. But on the
other hand one sometimes discovers that interesting solutions can be formed
using unexpected instructions (see the Push publications for some examples of
this). So the set of atom generators is something you'll probably want to
play with. The registered-with-type function can make it simpler to include
or exclude groups of instructions. This is demonstrated in some of the examples.

Other schushgp arguments to note include those that control genetic 
operators (mutation, crossover, and simplification). The specified operator
probabilities should sum to 1.0 or less -- any difference between the sum and
1.0 will be the probability for "straight" (unmodified) reproduction. The use
of simplification is also novel here. Push/Schush programs can be
automatically simplified -- to some extent -- in a very straightforward way:
because there are almost no syntax constraints you can remove anything (one
or more atoms or sub-lists, or a pair of parentheses) and still have a valid
program. So the automatic simplification procedure just iteratively removes
something, checks to see what that does to the error, and keeps the simpler
program if the error is the same (or lower!).

Automatic simplification is used in SchushGP in three places: 

1. There is a genetic operator that adds the simplified program to the next
generation's population. The use of the simplification genetic operator will
tend to keep programs smaller, but whether this has benificial or detrimental
effects on search performance is a subject for future research.

2. A specified number of simplification iterations is performed on the best 
program in each generation. This is produced only for the sake of the report, 
and the result is not added to the population. It is possible that the simplified
program that is displayed will actually be better than the best program in the
population. Note also that the other data in the report concerning the "best"
program refers to the unsimplified program.

3. Simplification is also performed on solutions at the ends of runs. 

Note that the automatic simplification procedure will not always find all
possible simplifications even if you run it for a large number of iterations,
but in practice it does often seem to eliminate a lot of useless code (and to
make it easier to perform further simplification by hand).

I've added some basic graphical plots to the reports that schushgp produces 
each generation, showing the errors of the current best program and the
progression of the total error over generations. This was a quick hack in
DrScheme, and it could certainly be improved in several ways. If you are
running SchushGP in a non-GUI environment (such as mzscheme) then
the plots will not appear.

If you've read this far then the best way to go further is probably to read
and run the examples below -- search for "schushgp examples. As distributed
one relatively easy problem will be uncommented, but you can comment that one
out, uncomment another one, and run it.

Enjoy!

IMPLEMENTATION NOTES

A Schush interpreter state is represented here as a PLT Scheme hash table that
maps type names (symbols) to stacks (lists, with the top items listed first).

Schush instructions are names of Scheme procedures that take a Schush 
interpreter state as an argument and modify it destructively. The
define-registered syntactic form is used to establish the definitions and
also to record the instructions in the global list registered-instructions.
Most instructions that work the same way for more than one type are
implemented using a higher-order procedure that takes a type (a quoted symbol
like 'integer or 'code) and returns a procedure that takes an interpreter
state and modifies it appropriately. For example there's a procedure called
popper that takes a type and returns a procedure -- that procedure takes a
state and pops the right stack in the state. This allows us to define
integer.pop with a simple form:

(define-registered integer.pop (popper 'integer))

In many versions of Push RUNPUSH takes initialization code or initial stack 
contents, along with a variety of other parameters. The implementation of
run-schush here takes only the code to be run and the state to modify. Other
parameters are set globally in the parameters section below. At some point
some of these may be turned into arguments to run-schush so that they aren't
global.

Miscellaneous differences between Schush and Push3 as described in the Push3
specification: 
- Schush Boolean literals are #t and #f (instead of TRUE and FALSE in the Push3
  spec). The original design decision was based on the fact that Common Lisp's
  native Boolean literals couldn't used without conflating false and the empty
  list (both NIL in Common Lisp).
- Schush adds exec.noop (same as code.noop).

Push3 stuff not (yet) implemented:
- NAME type/stack/instructions
- Other missing instructions:
  *.SHOVE, *.DEFINE, CODE.CONTAINS, CODE.CONTAINER, CODE.DEFINITION,
  CODE.DISCREPANCY, CODE.EXTRACT, CODE.INSERT, CODE.INSTRUCTIONS,
  CODE.POSITION, CODE.SUBST, FLOAT.MOD
- There are no size limits on expressions produced by code/exec instructions -- 
  this might cause crashes from exponential code growth.
- The configuration code and configuration files described in the Push3
  spec have not been implemented here. The approach here is quite different,
  so this may never be implemented

TO DO (SOMETIME, MAYBE)

- Implement remaining instructions in the Push3 specification.
- Add more examples.
- Add support for seeding the random number generator.
- Implement size limits on expressions produced by code/exec instructions.
- Add improved genetic operators, e.g. fair mutation/crossover and
  constant-perturbing mutations.
- Improve the automatic simplification algorithm.
- Possibly rename the auxiliary stack the "input" stack if no other
  uses are developed for it.

VERSION HISTORY
20090805: Started.
20090901: First version I was willing to share.
20090905: - Conditionalized graphics.
          - Improved documentation/format. 
          - Autosimplification in generation reports.
          - Run SchushGP example by default
          - New argument to run-schush and eval-schush to allow step-by-step
            printing of state during execution.
20090919: - New shuffle algorithm (slightly slower but conses less, more elegant).
          - Removed number-list in favor of in-range (faster, conses less, more
            elegant, but PLT-specific).
20090920: - Added explicit copyright and GPL notice, replacing previous disclaimers.
          - Interpreter states now printed in human-friendly form by run-schush
            when called with print argument #t; based on code by Thomas Helmuth.
20091226: - Added float.sin, float.cos, float.tan.
20091229: - Added scale-errors parameter to schushgp; when #t this calculates
            scaled errors via the Historically Assessed Hardness (HAH) method (in the
            "current generation / quotient" setting) and uses these scaled errors
            as the basis of selection. HAH is described in:
              Klein, J., and L. Spector. 2008. Genetic Programming with Historically
              Assessed Hardness. In Genetic Programming Theory and Practice VI, edited by
              R. L. Riolo, T. Soule, and B. Worzel, pp. 61-74. New York: Springer-Verlag. 
              http://hampshire.edu/lspector/pubs/kleinspector-gptp08-preprint.pdf
            This form of HAH is similar but non-identical (for non-Boolean problems)
            to "implicit fitness sharing" as described by McKay in:
              McKay, R. I. 2001. An investigation of fitness sharing in genetic programming.
              The Australian J. of Intelligent Information Processing Systems, 7(1/2):43–51.
            Also added examples using the scale-errors parameter.
          - Added three schushgp parameters to control the number of iterations of
            automatic simplification performed at various times:
            - report-simplifications:
                the number performed for each schushgp generation report
            - final-report-simplifications:
                the number performed on successful results
            - reproduction-simplifications:
                the number performed by the simplification genetic operator
          - Fixed bug in cases for factorial example.
          - Added YANK and YANKDUP instructions for all types.
20100102: - Added trivial geography, controlled by a trivial-geography-radius parameter
            to schushgp; set this to zero (the default) for no trivial geography.
            Trivial geography is described in:
              Spector, L., and J. Klein. 2005. Trivial Geography in Genetic Programming.
              In Genetic Programming Theory and Practice III, edited by T. Yu, R.L. Riolo,
              and B. Worzel, pp. 109-124. Boston, MA: Kluwer Academic Publishers.
              http://hampshire.edu/lspector/pubs/trivial-geography-toappear.pdf
            Also added an example using trivial geography.
          - Made several minor corrections to the documentation.
20100103: - Added option to save execution traces. If the global parameter save-traces
            is #t then the global variable trace will contain an execution trace
            after each call to run-schush. A trace is a list of exec stack tops, listed
            last first.
20100121: - Eliminated calls to eval in Push program execution, speeding up all Push
            program execution significantly. This is done with an instruction name/procedure
            hash table to which instructions are added when registered. Note that now 
            ALL instructions that appear in Push programs must be defined with
            define-registered, rather than define.
          - Fixed examples in this file to define input instructions with define-registered.
          - Added compensatory mate selection, in which mates for crossover with individual 
            i are selected on the basis of low sums, over fitness cases, of the product
            of i's error and the crossover candidate's error. This is off by default but
            can be turned on by passing a value of #t to the compensatory-mate-selection
            argument of schushgp.
20100123: - Fixed bugs in orders in which exec.do*range and code.do*range pushed things
            onto the exec stack.
            

ACKNOWLEDGEMENTS

This code was improved by several helpful suggestions from Thomas Helmuth.

|#

#lang scheme
(require scheme/gui/dynamic)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; parameters

(define schush-types '(exec integer float code boolean auxiliary))
(define max-number-magnitude 1000000000000)
(define min-number-magnitude 1.0E-10)
(define top-level-push-code #t)
(define top-level-pop-code #f)
(define evalpush-limit 150)
(define save-traces #f)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; other globals

(define trace '())

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Namespace definition, for use in calls to eval (provide schush-namespace as a second argument).

(define-namespace-anchor schush)
(define schush-namespace (namespace-anchor->namespace schush))

;; test of eval with the namespace
;; (define frog (lambda (x y) (list x y)))
;; (eval '(frog 2 3) schush-namespace)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; random code generator

(define random-element 
  (lambda (list)
    ;; Returns a random element of the list.
    (list-ref list (random (length list)))))

;;(random-element '(a b c d e))

(define shuffle ; Returns a randomly re-ordered copy of list.
  (lambda (list)
    (if (< (length list) 2) 
        list
        (let ((item (list-ref list (random (length list)))))
          (cons item (shuffle (remove item list)))))))

;;(shuffle '(a b c d e))

(define decompose 
  (lambda (number max-parts)
    ;; Returns a list of at most max-parts numbers that sum to number.
    ;; The order of the numbers is not random (you may want to shuffle it).
    (if (or (<= max-parts 1) (<= number 1))
        (list number)
        (let ((this-part (+ 1 (random (- number 1)))))
          (cons this-part (decompose (- number this-part)
                                     (- max-parts 1)))))))

;;(decompose 20 6)
;;(shuffle (decompose 20 6))

(define random-code-with-size 
  (lambda (points atom-generators)
    ;; Returns a random expression containing the given number of points.
    (if (< points 2)
        (let ((element (random-element atom-generators)))
          (if (procedure? element)
              (element)
              element))
        (let ((elements-this-level (shuffle (decompose (- points 1) (- points 1)))))
          (map (lambda (size) (random-code-with-size size atom-generators)) elements-this-level)))))

;;(random-code-with-size 20 (list 3.14 'squid (lambda () (random 100))))

(define random-code 
  (lambda (max-points atom-generators)
    ; Returns a random expression containing max-points or less points
    (random-code-with-size (+ 1 (random max-points)) atom-generators)))

;;(random-code 100 (list 3.14 'squid (lambda () (random 100))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; utilities

(define copy-tree 
  (lambda (tree)
    (cond ((null? tree) '())
          ((list? tree) (cons (copy-tree (car tree)) (copy-tree (cdr tree))))
          (#t tree))))

(define ensure-list
  (lambda (thing)
    (if (list? thing)
        thing
        (list thing))))
  
(define keep-number-reasonable
  (lambda (n)
    "Returns a version of n that obeys limit parameters."
    (if (integer? n)
        (cond ((> n max-number-magnitude) max-number-magnitude)
              ((< n (- max-number-magnitude)) (- max-number-magnitude))
              (else n))
        (cond ((> n max-number-magnitude) (* 1.0 max-number-magnitude))
              ((< n (- max-number-magnitude)) (* 1.0 (- max-number-magnitude)))
              ((and (< n min-number-magnitude)
                    (> n (- min-number-magnitude)))
               0.0)
              (else n)))))

; (printf "~a~n" (keep-number-reasonable -312987231987329187329187321987231987))

(define count-points 
  (lambda (tree)
    ;; Returns the number of points in tree, where each atom and each
    ;; pair of parentheses counts as a point.
    (if (list? tree)
        (+ 1 (apply + (map count-points tree)))
        1)))

;; (count-points '((this) program (contains (9 points))))

(define code-at-point-recursive
  (lambda (tree point-index)
    ;; A utility for code-at-point. Assumes point-index is in range.
    (if (zero? point-index)
        tree
        (let ((subtrees tree)
              (points-so-far 1))
          (do ((points-in-first-subtree (count-points (car subtrees))
                                        (count-points (car subtrees))))
            ((< point-index (+ points-so-far points-in-first-subtree))
             (code-at-point-recursive (first subtrees)
                                      (- point-index points-so-far)))
            (set! points-so-far (+ points-so-far points-in-first-subtree))
            (set! subtrees (cdr subtrees)))))))

;; (for ((i (in-range 7))) (printf "~%~A" (code-at-point-recursive '(a (b (c) d)) i)))

(define code-at-point 
  (lambda (tree point-index)
    ;; Returns a subtree of tree indexed by point-index in a depth first traversal.
    (if (null? tree)
        '()
        (code-at-point-recursive 
         tree 
         (abs (modulo (abs point-index) (count-points tree)))))))

;; (for ((i (in-range 20))) (printf "~%~A: ~A" (- i 10) (code-at-point  '(a (b (c) d)) (- i 10))))

(define insert-code-at-point-recursive 
  (lambda (tree point-index new-subtree)
    ;; A utility for insert-code-at-point. Assumes point-index is in range.
    (if (zero? point-index)
        new-subtree
        (let ((skipped-subtrees '())
              (remaining-subtrees tree)
              (points-so-far 1))
          (do ((points-in-first-subtree (count-points (car remaining-subtrees))
                                        (count-points (car remaining-subtrees))))
            ((< point-index (+ points-so-far points-in-first-subtree))
             (append skipped-subtrees
                     (list (insert-code-at-point-recursive
                            (car remaining-subtrees) 
                            (- point-index points-so-far)
                            new-subtree))
                     (cdr remaining-subtrees)))
            (set! points-so-far (+ points-so-far points-in-first-subtree))
            (set! skipped-subtrees (append skipped-subtrees
                                           (list (car remaining-subtrees))))
            (set! remaining-subtrees (cdr remaining-subtrees)))))))

;; (for ((i (in-range 7))) (printf "~%~A" (insert-code-at-point-recursive '(a (b (c) d)) i 'SPAM)))

(define insert-code-at-point 
  (lambda (tree point-index new-subtree)
    ;; Returns a copy of tree with the subtree formerly indexed by
    ;; point-index (in a depth-first traversal) replaced by new-subtree.
    (if (null? tree)
        new-subtree
        (insert-code-at-point-recursive (copy-tree tree)
                                        (abs (modulo (abs point-index) (count-points tree)))
                                        (copy-tree new-subtree)))))

;; (for ((i (in-range 20))) (printf "~%~A: ~A" (- i 10) (insert-code-at-point  '(a (b (c) d)) (- i 10) 'SPAM)))

(define trunc
  (lambda (n)
    ;; Truncates and converts to an exact (integer) number.
    (inexact->exact (truncate n))))

(define plot-data
  (if (gui-available?)
      (lambda (data x-label y-label)
        ((dynamic-require 'plot 'plot)
         ((dynamic-require 'plot 'points) (for/list ((i (in-range (length data))))
                                            (vector i (list-ref data i)))
                                          #:sym 'oplus)
         #:x-min 0
         #:x-max (length data)
         #:y-min 0
         #:y-max (+ 1 (apply max data))
         #:x-label x-label
         #:y-label y-label))
      void))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; states, stacks, and instructions

(define make-schush-state
  (lambda ()
    ;; Returns an empty schush state.
    (let ((state (make-hasheq)))
      (for ((type schush-types))
           (hash-set! state type '()))
      state)))

;;(make-schush-state)

(define registered-instructions '())

(define register-instruction 
  (lambda (name)
    (set! registered-instructions (cons name registered-instructions))))

(define instruction-table (make-hash))

(define-syntax (define-registered stx)
  (syntax-case stx ()
      ((_ instruction definition)
       #`(begin (define instruction definition)
                (register-instruction 'instruction)
                (hash-set! instruction-table 'instruction definition)))))

;(define-registered schmoo (lambda () (print 'hello)))
      
(define get-stack
  (lambda (type state)
    ;; Returns the current stack of the given type from the given state.
    (hash-ref state type)))

(define state-pretty-print ;; adapted from code written by Thomas Helmuth
  (lambda (state)
    (map (lambda (type)
           (printf "- ~A: ~A~%" type (get-stack type state)))
         schush-types)))

;;(state-pretty-print (make-schush-state) 0 'none)

;; (get-stack 'integer (make-schush-state))

(define push 
  (lambda (value type state)
    ;; Destructively modifies state to have value pushed on top of the type stack.
    ;; This is just a utility, not for use as an instruction in Push programs.
    (hash-set! state type (cons value (get-stack type state)))))

;;(let ((s (make-schush-state)))
;;  (push 'froggy 'code s)
;;  s)

(define top
  (lambda (type state)
    ;; Returns the top item of the type stack in state.
    ;; Returns 'no-stack-item if called on an empty stack
    ;; This is just a utility, not for use as an instruction in Push programs.
    (let ((stack (get-stack type state)))
      (if (null? stack)
          'no-stack-item
          (car stack)))))


(define stack-ref
  (lambda (type position state)
    ;; Returns the indicated item of the type stack in state.
    ;; Returns 'no-stack-item if called on an empty stack
    ;; This is just a utility, not for use as an instruction in Push programs.
    ;; NOT SAFE for invalid positions.
    (let ((stack (get-stack type state)))
      (if (null? stack)
          'no-stack-item
          (list-ref stack position)))))

(define pop
  (lambda (type state)
    ;; Destructively pops the stack of type in stage. Also returns the popped item
    ;; or 'no-stack-element if called on an empty stack.
    ;; This is just a utility, not for use as an instruction in Push programs.
    (let ((stack (get-stack type state)))
      (if (null? stack)
          'no-stack-element
          (let ((top-item (car stack)))
            (hash-set! state type (cdr stack))
            top-item)))))

;;(let ((s (make-schush-state)))
;;  (push 1 'integer s)
;;  (push 2 'integer s)
;;  (print s)(newline)
;;  (print (list 'top 'is (top 'integer s)))(newline)
;;  (pop 'integer s)
;;  (print (list 'top 'is (top 'integer s)))(newline)
;;  (print s)(newline))

(define prefix?
  (lambda (prefix str)
    ;; Return #t if prefix-string is a prefix of string.
    (cond ((zero? (string-length prefix))
           #t)
          ((zero? (string-length str))
           #f)
          ((equal? (string-ref prefix 0) (string-ref str 0))
           (prefix? (substring prefix 1) (substring str 1)))
          (#t
           #f))))

;(prefix? "integer" "integer.+")
;(prefix? "integer" "float.+")

(define registered-for-type
  (lambda (type)
    (filter (lambda (instr) (prefix? (symbol->string type) (symbol->string instr)))
            registered-instructions)))
              

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ACTUAL INSTRUCTIONS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; instructions for all types (except auxiliary)

(define popper 
  (lambda (type)
  ;; Returns a function that takes a state and pops the appropriate stack of the state.
    (lambda (state)
      (pop type state))))

(define-registered exec.pop (popper 'exec))
(define-registered integer.pop (popper 'integer))
(define-registered float.pop (popper 'float))
(define-registered code.pop (popper 'code))
(define-registered boolean.pop (popper 'boolean))

;(let ((s (make-schush-state)))
;  (push 23 'integer s)
;  (print s)(newline)
;  (integer.pop s)
;  (print s))
  

(define duper 
  (lambda (type)
  ;; Returns a function that takes a state and duplicates the top item of the appropriate stack of the state.
    (lambda (state)
      (let ((top-item (top type state)))
        (unless (eq? top-item 'no-stack-item)
          (push top-item type state))))))

(define-registered exec.dup (duper 'exec))
(define-registered integer.dup (duper 'integer))
(define-registered float.dup (duper 'float))
(define-registered code.dup (duper 'code))
(define-registered boolean.dup (duper 'boolean))

;(let ((s (make-schush-state)))
;  (push 23 'integer s)
;  (print s)(newline)
;  (integer.dup s)
;  (print s))

(define swapper 
  (lambda (type)
    ;; Returns a function that takes a state and swaps the top 2 items of the appropriate stack of the state.
    (lambda (state)
      (let ((stk (get-stack type state)))
        (unless (< (length stk) 2)
          (let ((top-item (car stk))
                (second-item (cadr stk)))
            (pop type state)
            (pop type state)
            (push top-item type state)
            (push second-item type state)))))))

(define-registered exec.swap (swapper 'exec))
(define-registered integer.swap (swapper 'integer))
(define-registered float.swap (swapper 'float))
(define-registered code.swap (swapper 'code))
(define-registered boolean.swap (swapper 'boolean))

;(let ((s (make-schush-state)))
;  (push 2 'integer s)
;  (push 3 'integer s)
;  (printf "~a~n" s)
;  (integer.swap s)
;  (printf "~a~n" s))

(define rotter 
  (lambda (type)
    ;; Returns a function that takes a state and rotates the top 3 items of the appropriate stack of the state.
    (lambda (state)
      (let ((stk (get-stack type state)))
        (unless (< (length stk) 3)
          (let ((top-item (car stk))
                (second-item (cadr stk))
                (third-item (caddr stk)))
            (pop type state)
            (pop type state)
            (pop type state)
            (push second-item type state)
            (push top-item type state)
            (push third-item type state)))))))

(define-registered exec.rot (rotter 'exec))
(define-registered integer.rot (rotter 'integer))
(define-registered float.rot (rotter 'float))
(define-registered code.rot (rotter 'code))
(define-registered boolean.rot (rotter 'boolean))

;(let ((s (make-schush-state)))
;  (push 1 'integer s)
;  (push 2 'integer s)
;  (push 3 'integer s)
;  (printf "~a~n" s)
;  (integer.rot s)
;  (printf "~a~n" s))

(define flusher
  (lambda (type)
    ;; Returns a function that empties the stack of the given state.
    (lambda (state)
      (hash-set! state type '()))))

(define-registered exec.flush (flusher 'exec))
(define-registered integer.flush (flusher 'integer))
(define-registered float.flush (flusher 'float))
(define-registered code.flush (flusher 'code))
(define-registered boolean.flush (flusher 'boolean))

;(let ((s (make-schush-state)))
;  (push 1 'integer s)
;  (push 2 'integer s)
;  (push 3 'integer s)
;  (printf "~a~n" s)
;  (integer.flush s)
;  (printf "~a~n" s))

(define =er 
  (lambda (type)
    ;; Returns a function that compares the top two items of the appropriate stack of the given state.
    (lambda (state)
      (let ((stk (get-stack type state)))
        (unless (< (length stk) 2)
          (let ((top-item (car stk))
                (second-item (cadr stk)))
            (pop type state)
            (pop type state)
            (push (equal? top-item second-item)'boolean state)))))))

(define-registered exec.= (=er 'exec))
(define-registered integer.= (=er 'integer))
(define-registered float.= (=er 'float))
(define-registered code.= (=er 'code))
(define-registered boolean.= (=er 'boolean))

;(let ((s (make-schush-state)))
;  (push 1 'integer s)
;  (push 2 'integer s)
;  (push 3 'integer s)
;  (printf "~a~n" s)
;  (integer.= s)
;  (printf "~a~n" s))

(define stackdepther
  (lambda (type)
    ;; Returns a function that pushes the depth of the appropriate stack of the the given state.
    (lambda (state)
      (push (length (get-stack type state)) 'integer state))))

(define-registered exec.stackdepth (stackdepther 'exec))
(define-registered integer.stackdepth (stackdepther 'integer))
(define-registered float.stackdepth (stackdepther 'float))
(define-registered code.stackdepth (stackdepther 'code))
(define-registered boolean.stackdepth (stackdepther 'boolean))

;(let ((s (make-schush-state)))
;  (push 1 'integer s)
;  (push 2 'integer s)
;  (push 3 'integer s)
;  (printf "~a~n" s)
;  (integer.stackdepth s)
;  (printf "~a~n" s))

(define yanker
  (lambda (type)
    ;; Returns a function that yanks an item from deep in the specified stack,
    ;; using the top integer to indicate how deep.
    (lambda (state)
      (let ((stk (get-stack type state))
            (int-stk (get-stack 'integer state)))
        (unless (or (null? int-stk)
                    (if (equal? type 'integer)
                        (null? (rest int-stk))
                        (null? stk)))
          (let ((raw-yank-index (first int-stk)))
            (pop 'integer state)
            (set! stk (get-stack type state)) ;; in case it's integers
            (let* ((yank-index (max 0 (min raw-yank-index (- (length stk) 1))))
                   (item (list-ref stk yank-index))
                   (stk-without-item (append (take stk yank-index)
                                             (drop stk (+ yank-index 1)))))
              (hash-set! state type (cons item stk-without-item)))))))))

(define-registered exec.yank (yanker 'exec))
(define-registered integer.yank (yanker 'integer))
(define-registered float.yank (yanker 'float))
(define-registered code.yank (yanker 'code))
(define-registered boolean.yank (yanker 'boolean))

;(let ((s (make-schush-state)))
;  (push 10 'integer s)
;  (push 20 'integer s)
;  (push 30 'integer s)
;  (push 1 'integer s)
;  (printf "~a~n" s)
;  (integer.yank s)
;  (printf "~a~n" s))
;
;(let ((s (make-schush-state)))
;  (push #t 'boolean s)
;  (push #f 'boolean s)
;  (push #t 'boolean s)
;  (push 1 'integer s)
;  (printf "~a~n" s)
;  (boolean.yank s)
;  (printf "~a~n" s))

(define yankduper
  (lambda (type)
    ;; Returns a function that yanks a copy of an item from deep in the 
    ;; specified stack, using the top integer to indicate how deep.
    (lambda (state)
      (let ((stk (get-stack type state))
            (int-stk (get-stack 'integer state)))
        (unless (or (null? int-stk)
                    (if (equal? type 'integer)
                        (null? (rest int-stk))
                        (null? stk)))
          (let ((raw-yank-index (first int-stk)))
            (pop 'integer state)
            (set! stk (get-stack type state)) ;; in case it's integers
            (let* ((yank-index (max 0 (min raw-yank-index (- (length stk) 1))))
                   (item (list-ref stk yank-index)))
              (hash-set! state type (cons item stk)))))))))

(define-registered exec.yankdup (yankduper 'exec))
(define-registered integer.yankdup (yankduper 'integer))
(define-registered float.yankdup (yankduper 'float))
(define-registered code.yankdup (yankduper 'code))
(define-registered boolean.yankdup (yankduper 'boolean))

;(let ((s (make-schush-state)))
;  (push 10 'integer s)
;  (push 20 'integer s)
;  (push 30 'integer s)
;  (push 1 'integer s)
;  (printf "~a~n" s)
;  (integer.yankdup s)
;  (printf "~a~n" s))
;
;(let ((s (make-schush-state)))
;  (push #t 'boolean s)
;  (push #f 'boolean s)
;  (push #t 'boolean s)
;  (push 1 'integer s)
;  (printf "~a~n" s)
;  (boolean.yankdup s)
;  (printf "~a~n" s))
              
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; instructions for numbers

(define adder
  (lambda (type)
    ;; Returns a function that pushes the sum of the top two items.
    (lambda (state)
      (let ((stk (get-stack type state)))
        (unless (< (length stk) 2)
          (let ((top-item (car stk))
                (second-item (cadr stk)))
            (pop type state)
            (pop type state)
            (push (keep-number-reasonable (+ second-item top-item)) type state)))))))

(define-registered integer.+ (adder 'integer))
(define-registered float.+ (adder 'float))

;(let ((s (make-schush-state)))
;  (push 1 'integer s)
;  (push 2 'integer s)
;  (integer.+ s)
;  (printf "~a~n" s))

(define subtracter
  (lambda (type)
    ;; Returns a function that pushes the difference of the top two items.
    (lambda (state)
      (let ((stk (get-stack type state)))
        (unless (< (length stk) 2)
          (let ((top-item (car stk))
                (second-item (cadr stk)))
            (pop type state)
            (pop type state)
            (push (keep-number-reasonable (- second-item top-item)) type state)))))))

(define-registered integer.- (subtracter 'integer))
(define-registered float.- (subtracter 'float))

;(let ((s (make-schush-state)))
;  (push 1 'integer s)
;  (push 2 'integer s)
;  (integer.- s)
;  (printf "~a~n" s))

(define multiplier
  (lambda (type)
    ;; Returns a function that pushes the product of the top two items.
    (lambda (state)
      (let ((stk (get-stack type state)))
        (unless (< (length stk) 2)
          (let ((top-item (car stk))
                (second-item (cadr stk)))
            (pop type state)
            (pop type state)
            (push (keep-number-reasonable (* second-item top-item)) type state)))))))

(define-registered integer.* (multiplier 'integer))
(define-registered float.* (multiplier 'float))

;(let ((s (make-schush-state)))
;  (push 3 'integer s)
;  (push 2 'integer s)
;  (integer.* s)
;  (printf "~a~n" s))

(define divider
  (lambda (type)
    ;; Returns a function that pushes the quotient of the top two items.
    ;; Acts as a No-Op if the divisor would be zero.
    (lambda (state)
      (let ((stk (get-stack type state)))
        (unless (or (< (length stk) 2)
                    (zero? (car stk)))
          (let ((top-item (car stk))
                (second-item (cadr stk)))
            (pop type state)
            (pop type state)
            (let ((quotient (keep-number-reasonable
                             (if (equal? type 'integer)
                                 (trunc (/ second-item top-item))
                                 (/ second-item top-item)))))
              (push quotient type state))))))))

(define-registered integer./ (divider 'integer))
(define-registered float./ (divider 'float))

;(let ((s (make-schush-state)))
;  (push 13 'integer s)
;  (push 2 'integer s)
;  (integer./ s)
;  (printf "~a~n" s))

(define modder
  (lambda (type)
    ;; Returns a function that pushes the modulus of the top two items.
    ;; Acts as a No-Op if the divisor would be zero.
    (lambda (state)
      (let ((stk (get-stack type state)))
        (unless (or (< (length stk) 2)
                    (zero? (car stk)))
          (let ((top-item (car stk))
                (second-item (cadr stk)))
            (pop type state)
            (pop type state)
            (let ((m (keep-number-reasonable
                      (if (equal? type 'integer)
                          (trunc (modulo second-item top-item))
                          (modulo second-item top-item)))))
              (push m type state))))))))

(define-registered integer.% (modder 'integer))
;; (define-registered float.% (modder 'float)) ;; modulo defined only for integers, so handle specially if you want it

;(let ((s (make-schush-state)))
;  (push 13 'integer s)
;  (push 2 'integer s)
;  (integer.% s)
;  (printf "~a~n" s))

;(let ((s (make-schush-state)))
;  (push 13.0 'float s)
;  (push 2.0 'float s)
;  (float.% s)
;  (printf "~a~n" s))

(define <er 
  (lambda (type)
    ;; Returns a function that compares the top two items of the appropriate stack of the given state.
    (lambda (state)
      (let ((stk (get-stack type state)))
        (unless (< (length stk) 2)
          (let ((top-item (car stk))
                (second-item (cadr stk)))
            (pop type state)
            (pop type state)
            (push (< second-item top-item) 'boolean state)))))))

(define-registered integer.< (<er 'integer))
(define-registered float.< (<er 'float))

(define >er 
  (lambda (type)
    ;; Returns a function that compares the top two items of the appropriate stack of the given state.
    (lambda (state)
      (let ((stk (get-stack type state)))
        (unless (< (length stk) 2)
          (let ((top-item (car stk))
                (second-item (cadr stk)))
            (pop type state)
            (pop type state)
            (push (> second-item top-item) 'boolean state)))))))

(define-registered integer.> (>er 'integer))
(define-registered float.> (>er 'float))
  
(define-registered integer.fromboolean
  (lambda (state)
    (let ((stk (get-stack 'boolean state)))
      (unless (null? stk)
        (let ((item (car stk)))
          (pop 'boolean state)
          (push (if item 1 0) 'integer state))))))

(define-registered float.fromboolean
  (lambda (state)
    (let ((stk (get-stack 'boolean state)))
      (unless (null? stk)
        (let ((item (car stk)))
          (pop 'boolean state)
          (push (if item 1.0 0.0) 'float state))))))

(define-registered integer.fromfloat
  (lambda (state)
    (let ((stk (get-stack 'float state)))
      (unless (null? stk)
        (let ((item (car stk)))
          (pop 'float state)
          (push (trunc item) 'integer state))))))

(define-registered float.frominteger
  (lambda (state)
    (let ((stk (get-stack 'integer state)))
      (unless (null? stk)
        (let ((item (car stk)))
          (pop 'integer state)
          (push (* 1.0 item) 'float state))))))

(define minner 
  (lambda (type)
    (lambda (state)
      (let ((stk (get-stack type state)))
        (unless (< (length stk) 2)
          (let ((top-item (car stk))
                (second-item (cadr stk)))
            (pop type state)
            (pop type state)
            (push (min second-item top-item) type state)))))))

(define-registered integer.min (minner 'integer))
(define-registered float.min (minner 'float))

(define maxer 
  (lambda (type)
    (lambda (state)
      (let ((stk (get-stack type state)))
        (unless (< (length stk) 2)
          (let ((top-item (car stk))
                (second-item (cadr stk)))
            (pop type state)
            (pop type state)
            (push (max second-item top-item) type state)))))))

(define-registered integer.max (maxer 'integer))
(define-registered float.max (maxer 'float))

(define-registered float.sin
  (lambda (state)
    (let ((stk (get-stack 'float state)))
      (unless (< (length stk) 1)
        (let ((top-item (car stk)))
          (pop 'float state)
          (push (keep-number-reasonable (sin top-item)) 'float state))))))


(define-registered float.cos
  (lambda (state)
    (let ((stk (get-stack 'float state)))
      (unless (< (length stk) 1)
        (let ((top-item (car stk)))
          (pop 'float state)
          (push (keep-number-reasonable (cos top-item)) 'float state))))))


(define-registered float.tan
  (lambda (state)
    (let ((stk (get-stack 'float state)))
      (unless (< (length stk) 1)
        (let ((top-item (car stk)))
          (pop 'float state)
          (push (keep-number-reasonable (tan top-item)) 'float state))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; instructions for Booleans

(define-registered boolean.and
  (lambda (state)
    (let ((stk (get-stack 'boolean state)))
      (unless (< (length stk) 2)
        (let ((top-item (car stk))
              (second-item (cadr stk)))
          (pop 'boolean state)
          (pop 'boolean state)
          (push (and top-item second-item) 'boolean state))))))

(define-registered boolean.or
  (lambda (state)
    (let ((stk (get-stack 'boolean state)))
      (unless (< (length stk) 2)
        (let ((top-item (car stk))
              (second-item (cadr stk)))
          (pop 'boolean state)
          (pop 'boolean state)
          (push (or top-item second-item) 'boolean state))))))

(define-registered boolean.not
  (lambda (state)
    (let ((stk (get-stack 'boolean state)))
      (unless (< (length stk) 1)
        (let ((top-item (car stk)))
          (pop 'boolean state)
          (push (not top-item) 'boolean state))))))

(define-registered boolean.frominteger
  (lambda (state)
    (let ((stk (get-stack 'integer state)))
      (unless (< (length stk) 1)
        (let ((top-item (car stk)))
          (pop 'integer state)
          (push (if (zero? top-item) #f #t) 'boolean state))))))

(define-registered boolean.fromfloat
  (lambda (state)
    (let ((stk (get-stack 'float state)))
      (unless (< (length stk) 1)
        (let ((top-item (car stk)))
          (pop 'float state)
          (push (if (zero? top-item) #f #t) 'boolean state))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; code and exec instructions

(define-registered code.append
  (lambda (state)
    (let ((stk (get-stack 'code state)))
      (unless (< (length stk) 2)
        (let ((top-item (car stk))
              (second-item (cadr stk)))
          (pop 'code state)
          (pop 'code state)
          (push (append (ensure-list second-item) (ensure-list top-item)) 'code state))))))

(define-registered code.atom
  (lambda (state)
    (let ((stk (get-stack 'code state)))
      (unless (< (length stk) 1)
        (let ((top-item (car stk)))
          (pop 'code state)
          (push (not (pair? top-item)) 'code state))))))

(define-registered code.car
  (lambda (state)
    (let ((stk (get-stack 'code state)))
      (unless (null? stk)
        (let ((top-item (car stk)))
          (pop 'code state)
          (push (if (null? top-item) '() (car (ensure-list top-item))) 'code state))))))

(define-registered code.cdr
  (lambda (state)
    (let ((stk (get-stack 'code state)))
      (unless (null? stk)
        (let ((top-item (car stk)))
          (pop 'code state)
          (push (if (null? top-item) '() (cdr (ensure-list top-item))) 'code state))))))

(define-registered code.cons
  (lambda (state)
    (let ((stk (get-stack 'code state)))
      (unless (< (length stk) 2)
        (let ((top-item (car stk))
              (second-item (cadr stk)))
          (pop 'code state)
          (pop 'code state)
          (push (cons second-item (ensure-list top-item)) 'code state))))))

(define-registered code.do
  (lambda (state)
    (let ((stk (get-stack 'code state)))
      (unless (null? stk)
        (push 'code.pop 'exec state)
        (push (car stk) 'exec state)))))

(define-registered code.do*
  (lambda (state)
    (let ((stk (get-stack 'code state)))
      (unless (null? stk)
        (let ((top-item (car stk)))
          (pop 'code state)
          (push top-item 'exec state))))))

(define-registered code.do*range
  (lambda (state)
    (let ((istk (get-stack 'integer state))
          (cstk (get-stack 'code state)))
      (unless (or (null? cstk)
                  (< (length istk) 2))
        (let* ((to-do (car cstk))
               (current-index (cadr istk))
               (destination-index (car istk)))
          (pop 'code state)
          (pop 'integer state)
          (pop 'integer state)
          (let ((increment (cond ((< current-index destination-index) 1)
                                 ((> current-index destination-index) -1)
                                 (#t 0))))
            (push current-index 'integer state)
            (unless (zero? increment)  ;; recursive call
              (push (list (+ current-index increment) 
                          destination-index 
                          'code.quote 
                          (copy-tree to-do) 
                          'code.do*range)
                    'exec
                    state))
            (push (copy-tree to-do) 'exec state)))))))


(define-registered exec.do*range 
  (lambda (state)
  ;; differs from code.do*range only in the source of the code and the recursive call
    (let ((istk (get-stack 'integer state))
          (estk (get-stack 'exec state)))
      (unless (or (null? estk)
                  (< (length istk) 2))
        (let* ((to-do (car estk))
               (current-index (cadr istk))
               (destination-index (car istk)))
          (pop 'exec state)
          (pop 'integer state)
          (pop 'integer state)
          (let ((increment (cond ((< current-index destination-index) 1)
                                 ((> current-index destination-index) -1)
                                 (#t 0))))
            (push current-index 'integer state)
            (unless (zero? increment)  
              (push (list (+ current-index increment) ;; recursive call
                          destination-index 
                          'exec.do*range
                          (copy-tree to-do))
                    'exec
                    state))
            (push (copy-tree to-do) 'exec state)))))))

(define-registered code.do*count
  (lambda (state)
    (let ((istk (get-stack 'integer state))
          (cstk (get-stack 'code state)))
      (unless (or (null? istk)
                  (< (car istk) 1)
                  (null? cstk))
        (let ((to-do (car cstk))
              (num-times (car istk)))
          (pop 'integer state)
          (pop 'code state)
          (push (list 0 (- num-times 1) 'code.quote (copy-tree to-do) 'code.do*range)
                'exec
                state))))))

(define-registered exec.do*count
  (lambda (state)
    ;; differs from code.do*count only in the source of the code and the recursive call
    (let ((istk (get-stack 'integer state))
          (estk (get-stack 'exec state)))
      (unless (or (null? istk)
                  (< (car istk) 1)
                  (null? estk))
        (let ((to-do (car estk))
              (num-times (car istk)))
          (pop 'integer state)
          (pop 'exec state)
          (push (list 0 (- num-times 1) 'exec.do*range (copy-tree to-do))
                'exec
                state))))))

(define-registered code.do*times
  (lambda (state)
    (let ((istk (get-stack 'integer state))
          (cstk (get-stack 'code state)))
      (unless (or (null? istk)
                  (< (car istk) 1)
                  (null? cstk))
        (let ((to-do (car cstk))
              (num-times (car istk)))
          (pop 'integer state)
          (pop 'code state)
          (push (list 0 (- num-times 1) 'code.quote (cons 'integer.pop (ensure-list (copy-tree to-do))) 'code.do*range)
                'exec
                state))))))

(define-registered exec.do*times
  (lambda (state)
    ;; differs from code.do*times only in the source of the code and the recursive call
    (let ((istk (get-stack 'integer state))
          (estk (get-stack 'exec state)))
      (unless (or (null? istk)
                  (< (car istk) 1)
                  (null? estk))
        (let ((to-do (car estk))
              (num-times (car istk)))
          (pop 'integer state)
          (pop 'exec state)
          (push (list 0 (- num-times 1) 'exec.do*range (cons 'integer.pop (ensure-list (copy-tree to-do))))
                'exec
                state))))))

(define codemaker
  (lambda (type)
    (lambda (state)
      (let ((stk (get-stack type state)))
        (unless (null? stk)
          (let ((item (car stk)))
            (pop type state)
            (push item 'code state)))))))

(define-registered code.fromboolean (codemaker 'boolean))
(define-registered code.fromfloat (codemaker 'float))
(define-registered code.frominteger (codemaker 'integer))
(define-registered code.quote (codemaker 'exec))

(define-registered code.if
  (lambda (state)
    (let ((bstk (get-stack 'boolean state))
          (cstk (get-stack 'code state)))
      (unless (or (null? bstk)
                  (< (length cstk) 2))
        (let ((to-do (if (car bstk)
                         (cadr cstk)
                         (car cstk))))
          (pop 'boolean state)
          (pop 'code state)
          (pop 'code state)
          (push (copy-tree to-do) 'exec state))))))

(define-registered exec.if
  (lambda (state)
    ;; differs from code.if in the source of the code and in the order of the if/then parts
    (let ((bstk (get-stack 'boolean state))
          (estk (get-stack 'exec state)))
      (unless (or (null? bstk)
                  (< (length estk) 2))
        (let ((to-do (if (car bstk)
                         (car estk)
                         (cadr estk))))
          (pop 'boolean state)
          (pop 'exec state)
          (pop 'exec state)
          (push (copy-tree to-do) 'exec state))))))

(define-registered code.length
  (lambda (state)
    (let ((cstk (get-stack 'code state)))
      (unless (null? cstk)
        (let ((item (car cstk)))
          (pop 'code state)
          (if (list? item)
              (push (length item) 'integer state)
              (push 1 'integer state)))))))

(define-registered code.list
  (lambda (state)
    (let ((cstk (get-stack 'code state)))
      (unless (< (length cstk) 2)
        (let ((top-item (car cstk))
              (second-item (cadr cstk)))
          (pop 'code state)
          (pop 'code state)
          (push (list second-item top-item) 'code state))))))

(define-registered code.member
  (lambda (state)
    (let ((cstk (get-stack 'code state)))
      (unless (< (length cstk) 2)
        (let ((top-item (car cstk))
              (second-item (cadr cstk)))
          (pop 'code state)
          (pop 'code state)
          (push (not (not (member second-item (ensure-list top-item)))) 'boolean state))))))

(define nooper 
  (lambda (type)
    (lambda (state)
      (void))))

(define-registered exec.noop (nooper 'code))
(define-registered code.noop (nooper 'exec))

(define-registered code.nth
  (lambda (state)
    (let ((istk (get-stack 'integer state))
          (cstk (get-stack 'code state)))
      (unless (or (null? istk)
                  (null? cstk)
                  (null? (car cstk)))
        (let* ((the-list (ensure-list (car cstk)))
               (new-item (list-ref the-list (modulo (abs (car istk)) (length the-list)))))
          (pop 'integer state)
          (pop 'code state)
          (push new-item 'code state))))))

(define-registered code.nthcdr
  (lambda (state)
    (let ((istk (get-stack 'integer state))
          (cstk (get-stack 'code state)))
      (unless (or (null? istk)
                  (null? cstk)
                  (null? (car cstk)))
        (let* ((the-list (ensure-list (car cstk)))
               (new-item (list-tail the-list (modulo (abs (car istk)) (length the-list)))))
          (pop 'integer state)
          (pop 'code state)
          (push new-item 'code state))))))

(define-registered code.null
  (lambda (state)
    (let ((stk (get-stack 'code state)))
      (unless (null? stk)
        (let ((item (car stk)))
          (pop 'code state)
          (push (null? item) 'boolean state))))))

(define-registered code.size
  (lambda (state)
    (let ((cstk (get-stack 'code state)))
      (unless (null? cstk)
        (let ((item (car cstk)))
          (pop 'code state)
          (push (count-points item) 'integer state))))))

(define-registered exec.k
  (lambda (state)
    (let ((stk (get-stack 'exec state)))
      (unless (< (length stk) 2)
        (let ((item (car stk)))
          (pop 'exec state)
          (pop 'exec state)
          (push item 'exec state))))))

(define-registered exec.s
  (lambda (state)
    (let ((stk (get-stack 'exec state)))
      (unless (< (length stk) 3)
        (let ((x (car stk))
              (y (cadr stk))
              (z (caddr stk)))
          (pop 'exec state)
          (pop 'exec state)
          (pop 'exec state)
          (push (list y z) 'exec state)
          (push z 'exec state)
          (push x 'exec state))))))

(define-registered exec.y
  (lambda (state)
    (let ((stk (get-stack 'exec state)))
      (unless (null? stk)
        (let ((item (car stk)))
          (pop 'exec state)
          (push (list 'exec.y item) 'exec state)
          (push item 'exec state))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; print all registered instructions on loading

(printf "~nRegistered instructions: ~a~n" registered-instructions)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; schush interpreter

(define run-schush 
  (lambda (code state (print #f))
    ;; The top level of the push interpreter; calls eval-schush between appropriate code/exec pushing/popping.
    ;; Returns #t if terminated normally, #f otherwise.
    (if top-level-push-code
        (push code 'code state)
        #f)
    (push code 'exec state)
    (when print
      (printf "~%State after 0 steps:~%")
      (state-pretty-print state))
    (when save-traces (set! trace '()))
    (let ((normal-termination (eval-schush state print)))
      (if top-level-pop-code
          (pop 'code state)
          #f)
      normal-termination)))

(define eval-schush 
  (lambda (state (print #f))
    ;; Executes the contents of the exec stack, aborting 
    ;; prematurely if execution limits are exceeded.
    ;; Returns #t if terminated normally, #f otherwise.
    (do ((count 1 (+ 1 count)))
      ((or (> count evalpush-limit)
           (null? (get-stack 'exec state)))
       (<= count evalpush-limit))
      (let ((exec-top (top 'exec state)))
        (pop 'exec state)
        (when save-traces
          (set! trace (cons exec-top trace)))
        (if (list? exec-top)
            (hash-set! state 'exec (append exec-top (get-stack 'exec state)))
            (execute-instruction exec-top state))
        (when print
          (printf "~%State after ~A steps (last step: ~A):~%" 
                  count (if (list? exec-top) "(...)" exec-top))
          (state-pretty-print state))))))

(define recognize-literal
  (lambda (thing)
    ;; If thing is a literal, returh its type -- otherwise return #f.
    (cond ((and (integer? thing) (exact? thing)) 'integer)
          ((number? thing) 'float)
          ((boolean? thing) 'boolean)
          ;; if names are added then distinguish them from registered instructions here
          (else #f))))

;; execute-instruction, old version using eval
;(define execute-instruction 
;  (lambda (instruction state)
;    ;; Executes a single push instruction.
;    (let ((literal-type (recognize-literal instruction)))
;      (if literal-type
;          (push instruction literal-type state)
;          (unless (void? instruction)
;            ((eval instruction schush-namespace) state))))))

;; execute-instruction, version using lookup-instruction
(define execute-instruction 
  (lambda (instruction state)
    ;; Executes a single push instruction.
    (let ((literal-type (recognize-literal instruction)))
      (if literal-type
          (push instruction literal-type state)
          (unless (void? instruction)
            (if (procedure? instruction)
                (instruction state)
                ((hash-ref instruction-table instruction) state)))))))

;; test a specific simple program
;(let ((s (make-schush-state)))
;  (run-schush '(1 2 integer.+) s)
;  s)

;; test a random program and also print termination status
;(let ((s (make-schush-state))
;      (c (random-code 1000
;                      (append registered-instructions
;                              (list (lambda () (random 100))
;                                    (lambda () (random)))))))
;  (printf "~nCode: ~a~n" c)
;  (printf "~nTerminated normally?: ~A~n" (run-schush c s))
;  s)

;; test each instruction as a singlton program
;(for ((i registered-instructions))
;  (let ((s (make-schush-state))
;        (c (list i)))
;    (printf "~nCode: ~a~n" c)
;    (run-schush c s)
;    (printf "~nFinal state: ~a~n" s)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; schushgp

;; We represent an individual as a list (program errors total-error scaled-error).
(define individual-program (lambda (i) (car i)))
(define individual-errors (lambda (i) (cadr i)))
(define individual-total-error (lambda (i) (caddr i)))
(define individual-scaled-error (lambda (i) (cadddr i)))

(define report 
  (lambda (population generation error-function report-simplifications)
    ;; Reports on the specified generation of a schushgp run. Returns the best
    ;; individual of the generation.
    (printf "~%~%;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;")
    (printf "~%;; -*- Report at generation ~A" generation)
    (let* ((sorted (sort population < #:key individual-total-error))
           (best (car sorted)))
      (printf "~%Best program:~A" (individual-program best))
      (printf "~%Partial simplification (may beat best): ~A"
              (individual-program 
               (auto-simplify (individual-program best) error-function report-simplifications #f)))
      (printf "~%Errors: ~A" (individual-errors best))
      (printf "~%Total: ~A" (individual-total-error best))
      (printf "~%Scaled: ~A" (individual-scaled-error best))
      (printf "~%Size: ~A" (count-points (individual-program best)))
      (printf "~%~%Average total errors in population: ~A"
              (* 1.0 (/ (apply + (map individual-total-error sorted)) (length population))))
      (printf "~%Median total errors in population: ~A"
              (individual-total-error (list-ref sorted (trunc (/ (length sorted) 2)))))
      (printf "~%Average program size in population (points): ~A"
              (* 1.0 (/ (apply + (map (lambda (g) (count-points (individual-program g)))sorted))
                        (length population))))
      best)))

(define select
  (lambda (population tournament-size radius location)
    ; Conducts a tournament and returns the individual with the lower scaled error.
    (let ((tournament-set '()))
      (for ((i (in-range tournament-size)))
        (set! tournament-set (cons (list-ref population 
                                             (if (zero? radius)
                                                 (random (length population))
                                                 (modulo (+ location
                                                            (- (random (+ 1 (* radius 2)))
                                                               radius))
                                                         (length population))))
                                   tournament-set)))
      (car (sort tournament-set < #:key individual-scaled-error)))))

;(select '(((a b c) (1 2 3) 6)((a b c) (1 2 3) 7)((a b c) (1 2 3) 8)((a b c) (1 2 3) 9)((a b c) (1 2 3) 10))
;        3)

(define select-compensatory ;; for compensatory mate selection
  (lambda (population tournament-size radius location first-parent)
    (let ((tournament-set '()))
      (for ((i (in-range tournament-size)))
        (set! tournament-set (cons (list-ref population 
                                             (if (zero? radius)
                                                 (random (length population))
                                                 (modulo (+ location
                                                            (- (random (+ 1 (* radius 2)))
                                                               radius))
                                                         (length population))))
                                   tournament-set)))
      (car (sort tournament-set < #:key (lambda (ind)
                                          (apply +
                                                 (map *
                                                      (individual-errors ind)
                                                      (individual-errors first-parent)))))))))

(define mutate 
  (lambda (individual mutation-max-points max-points atom-generators)
    ;; Returns a mutated version of the given individual.
    (let ((new-program (insert-code-at-point (individual-program individual) 
                                             (random (count-points (individual-program individual)))
                                             (random-code mutation-max-points atom-generators))))
      (if (> (count-points new-program) max-points)
          individual
          (list new-program 'undefined 'undefined 'undefined)))))

;(mutate '((a (b (c) d) e) (1 2 3) 6) 15 '(x y z))

(define crossover 
  (lambda (parent1 parent2 max-points)
    ;; Returns a copy of parent1 with a random subprogram replaced with a random subprogram of parent2.
    (let ((new-program (insert-code-at-point (individual-program parent1) 
                                             (random (count-points (individual-program parent1)))
                                             (code-at-point (individual-program parent2)
                                                            (random (count-points (individual-program parent2)))))))
      (if (> (count-points new-program) max-points)
          parent1
          (list new-program 'undefined 'undefined 'undefined)))))

;(crossover '((a (b (c) d) e) (1 2 3) 6) '((x (y z (w))) (1 2 3) 6) 10)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; auto-simplify
;; code for automatically simplifying Push programs

(define remove-code-at-point 
  (lambda (tree point-index)
    (set! point-index (abs (modulo point-index (count-points tree))))
    (if (or (null? tree) (zero? point-index))
        '()
        (remove-funnymarker23
         (insert-code-at-point-recursive tree point-index 'FUNNYMARKER23)))))

(define remove-funnymarker23 
  (lambda (tree)
    (if (list? tree)
        (if (ormap list? tree)
            (map remove-funnymarker23 (filter-not (lambda (x) (equal? x 'FUNNYMARKER23)) tree))
            (filter-not (lambda (x) (equal? x 'FUNNYMARKER23)) tree))
        tree)))

;(remove-code-at-point '(a (b (c nil) e) f) 4)

(define auto-simplify 
  (lambda (program error-function steps print #:progress-interval (progress-interval 1000))
    ;; Auto-simplifies the profided program and returns an individual (program errors total).
    (when print (printf "~%Auto-simplifying with starting size: ~A" (count-points program)))
    (let* ((errors (error-function program))
           (backup-program program)
           (backup-errors errors)
           (simplification-report
            (lambda (s) 
              (when print (printf "~%step: ~A~%program: ~A~%errors: ~A~%total: ~A~%size: ~A~%" 
                                  s program errors (apply + errors) (count-points program))))))
      (for ((step (in-range steps)))
        (when (zero? (modulo step progress-interval)) (simplification-report step))
        (set! backup-program program)
        (set! backup-errors errors)
        (case (random 5)
          ;; remove small number of random things
          ((0 1 2 3) (for ((i (in-range (+ 1 (random 2)))))
                 (set! program (remove-code-at-point program (random (count-points program))))))
          ;; replace small number or random things with #<void>
          ;((3) (for ((i (in-range (+ 1 (random 2)))))
          ;       (set! program (insert-code-at-point program (random (count-points program)) (void)))))
          ;; flatten something
          ((4) (let* ((point-index (random (count-points program)))
                      (point (code-at-point program point-index)))
                 (when (list? point)
                   (set! program (insert-code-at-point program point-index (flatten point)))))))
        (set! errors (error-function program))
        (when (> (apply + errors) (apply + backup-errors))
          (set! program backup-program)
          (set! errors backup-errors)))
      (simplification-report steps)
      (list program errors (apply + errors) (apply + errors)))))

(define schushgp
  (lambda (#:error-function error-function ;; error-function should take a program and return a list of errors
                            #:error-threshold (error-threshold 0)
                            #:population-size (population-size 1000)
                            #:max-points (max-points 50)
                            #:atom-generators (atom-generators (append registered-instructions
                                                                       (list (lambda () (random 100))
                                                                             (lambda () (random)))))
                            #:max-generations (max-generations 1001)
                            #:mutation-probability (mutation-probability 0.4)
                            #:mutation-max-points (mutation-max-points 20)
                            #:crossover-probability (crossover-probability 0.4)
                            #:simplification-probability (simplification-probability 0.1)
                            #:tournament-size (tournament-size 7)
                            #:scale-errors (scale-errors #f)
                            #:report-simplifications (report-simplifications 100)
                            #:final-report-simplifications (final-report-simplifications 1000)
                            #:reproduction-simplifications (reproduction-simplifications 25)
                            #:trivial-geography-radius (trivial-geography-radius 0) ;; 0 means no trivial geography
                            #:compensatory-mate-selection (compensatory-mate-selection #f))
    ;; The top-level routine of schushgp.
    ;; print parameters
    (printf "~%Starting SchushGP run.~%Error function: ~A~%Error threshold: ~A~%Population size: ~A~%Max points: ~A"
            error-function error-threshold population-size max-points)
    (printf "~%Atom generators: ~A~%Max generations: ~A~%Mutation probability: ~A~%Mutation max points: ~A"
            atom-generators max-generations mutation-probability mutation-max-points)
    (printf "~%Crossover probability: ~A~%Simplification probability: ~A~%Tournament size: ~A" 
            crossover-probability simplification-probability tournament-size)
    (printf "~%Scale errors: ~A" scale-errors)
    (printf "~%Report simplifications: ~A" report-simplifications)
    (printf "~%Final report simplifications: ~A" final-report-simplifications)
    (printf "~%Reproduction simplifications: ~A" reproduction-simplifications)
    (printf "~%Trivial geography radius: ~A" trivial-geography-radius)
    (printf "~%Compensatory mate selection: ~A" compensatory-mate-selection)
    (printf "~%~%")
    (printf "~%Generating initial population...")
    (let ((population (for/list ((iteration (in-range population-size)))
                        (list (random-code max-points atom-generators) 'undefined 'undefined)))
          (historical-total-errors '()))
      (call/cc 
       (lambda (continuation)
         ;; loop for each generation
         (for ((generation (in-range max-generations)))
           (printf "~%Generation: ~A" generation)
           ;; compute errors
           (printf "~%Computing errors...")
           (set! population (map (lambda (i)
                                   (let* ((errors (if (list? (individual-errors i))
                                                      (individual-errors i)
                                                      (error-function (individual-program i))))
                                          (total-error (if (and (number? (individual-total-error i))
                                                                (not scale-errors))
                                                           (individual-total-error i)
                                                           (keep-number-reasonable (apply + errors)))))
                                     (list (individual-program i) errors total-error total-error)))
                                 population))
           ;; scale total errors by historically assessed hardness (current generation, quotient method, normalized)
           (when scale-errors
             (printf "~%Scaling errors...")
             (let* ((num-cases (length (individual-errors (first population))))
                    (per-case-threshold (/ error-threshold num-cases))
                    (cumulative-successes (build-vector num-cases (lambda (i) 0))))
               (for ((individual population))
                 (for ((case (in-range 0 num-cases)))
                   (vector-set! cumulative-successes
                                case
                                (+ (vector-ref cumulative-successes case)
                                   (if (<= (list-ref (individual-errors individual) case) per-case-threshold)
                                       1
                                       0)))))
               (set! population (map (lambda (i)
                                       (list (first i)
                                             (second i)
                                             (third i)
                                             (let ((errors (second i))
                                                   (scaled-error 0.0))
                                               (for ((case (in-range 0 (length errors))))
                                                 (set! scaled-error
                                                       (+ scaled-error (/ (list-ref errors case)
                                                                          (+ 1 (vector-ref cumulative-successes case))))))
                                               scaled-error)))
                                     population))))
           ;; report and check for success
           (let ((best (report population generation error-function report-simplifications)))
             (set! historical-total-errors (append historical-total-errors (list (individual-total-error best))))
             (when (gui-available?)
               (printf "~%~A~A~%" 
                       (plot-data (individual-errors best) "case" "current best program error")
                       (plot-data historical-total-errors "generation" "historical best program total error")))
             (when (<= (individual-total-error best) error-threshold)
               (printf "~%~%SUCCESS at generation ~A~%Successful program: ~A~%Errors: ~A~%Total error: ~A~%Size: ~A~%~%"
                       generation
                       (individual-program best)
                       (individual-errors best)
                       (individual-total-error best)
                       (count-points (individual-program best)))
               ;; auto-simplify result
               (auto-simplify (individual-program best) error-function final-report-simplifications #t)
               ;; exit generation loop
               (continuation)))
           ;; produce next generation
           (printf "~%Producing offspring...")
           (set! population 
                 (for/list ((iteration (in-range population-size)))
                   (let ((n (random)))
                     (cond ((< n mutation-probability)
                            (mutate (select population tournament-size trivial-geography-radius iteration) 
                                    mutation-max-points max-points atom-generators))
                           ((< n (+ mutation-probability crossover-probability))
                            (let* ((first-parent 
                                    (select population tournament-size trivial-geography-radius iteration))
                                   (second-parent
                                    (if compensatory-mate-selection
                                        (select-compensatory
                                         population tournament-size trivial-geography-radius iteration first-parent)
                                        (select population tournament-size trivial-geography-radius iteration))))
                              (crossover first-parent second-parent max-points)))
                           ((< n (+ mutation-probability crossover-probability simplification-probability))
                            (auto-simplify 
                             (individual-program (select population tournament-size trivial-geography-radius iteration)) 
                             error-function reproduction-simplifications #f))
                           (#t (select population tournament-size trivial-geography-radius iteration)))))))
         ;; If we get here we've finished the generations but failed.
         (printf  "~%FAILURE~%"))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; profiling

;(require profile)
;(profile-thunk
; (lambda ()
;   (schushgp
;    #:error-function (lambda (program)
;                       (for/list ((input (in-range 10)))
;                         (let ((state (make-schush-state)))
;                           (push input 'integer state)
;                           (run-schush program state)
;                           (random 100))))
;    #:max-generations 2)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; schushgp examples

;;;;;;;;;;;;
;; Integer symbolic regression of x^2 with all instructions default parameters -- pretty easy, even though the instruction
;; set is huge.

;(schushgp 
; #:error-function (lambda (program) 
;                    (for/list ((input (in-range 10)))         ;; for inputs from 0 to 9
;                      (let ((state (make-schush-state)))         ;; make an empty state
;                        (push input 'integer state)              ;; push the input
;                        (run-schush program state)               ;; run the program
;                        (let ((top-int (top 'integer state)))    ;; and return the error
;                          (if (number? top-int)                  ;; which is the difference between the stack top
;                              (abs (- top-int (* input input)))  ;; and the square of the input
;                              1000))))))                         ;; or a high penalty value if there's no number on the stack

;;;;;;;;;;;;
;; The same thing but with only integer instructions and literals -- easier!

;(schushgp 
; #:error-function (lambda (program) 
;                    (for/list ((input (in-range 10)))         ;; for inputs from 0 to 9
;                      (let ((state (make-schush-state)))         ;; make an empty state
;                        (push input 'integer state)              ;; push the input
;                        (run-schush program state)               ;; run the program
;                        (let ((top-int (top 'integer state)))    ;; and return the error
;                          (if (number? top-int)                  ;; which is the difference between the stack top
;                              (abs (- top-int (* input input)))  ;; and the square of the input
;                              1000)))))                          ;; or a high penalty value if there's no number on the stack
; #:atom-generators (cons (lambda () (random 100))
;                         (registered-for-type 'integer)))

;;;;;;;;;;;;
;; Integer symbolic regression of x^3 - 2x^2 - x (problem 5 from the trivial geography chapter) with 
;; minimal integer instructions and an input instruction that uses the auxiliary stack.

;; (define-registered in (lambda (state) (push (stack-ref 'auxiliary 0 state) 'integer state)))

;; (schushgp #:error-function (lambda (program) 
;;                              (for/list ((input (in-range 10)))
;;                                (let ((state (make-schush-state)))
;;                                  (push input 'integer state)
;;                                  (push input 'auxiliary state)
;;                                  (run-schush program state)
;;                                  (let ((top-int (top 'integer state)))
;;                                    (if (number? top-int)
;;                                        (abs (- top-int (- (* input input input) (* 2 input input) input)))
;;                                        1000)))))
;;           #:atom-generators (list (lambda () (random 10))
;;                                   'in
;;                                   'integer./
;;                                   'integer.*
;;                                   'integer.-
;;                                   'integer.+
;;                                   'integer.dup))


;;;;;;;;;;;;
;; Same thing but with error scaling.

;(define-registered in (lambda (state) (push (stack-ref 'auxiliary 0 state) 'integer state)))
;
;(schushgp #:error-function (lambda (program) 
;                             (for/list ((input (in-range 10)))
;                               (let ((state (make-schush-state)))
;                                 (push input 'integer state)
;                                 (push input 'auxiliary state)
;                                 (run-schush program state)
;                                 (let ((top-int (top 'integer state)))
;                                   (if (number? top-int)
;                                       (abs (- top-int (- (* input input input) (* 2 input input) input)))
;                                       1000)))))
;          #:atom-generators (list (lambda () (random 10))
;                                  'in
;                                  'integer./
;                                  'integer.*
;                                  'integer.-
;                                  'integer.+
;                                  'integer.dup)
;          #:scale-errors #t)

;;;;;;;;;;;;
;; Same thing (without error scaling) but with trivial geography.

;(define-registered in (lambda (state) (push (stack-ref 'auxiliary 0 state) 'integer state)))
;
;(schushgp #:error-function (lambda (program) 
;                             (for/list ((input (in-range 10)))
;                               (let ((state (make-schush-state)))
;                                 (push input 'integer state)
;                                 (push input 'auxiliary state)
;                                 (run-schush program state)
;                                 (let ((top-int (top 'integer state)))
;                                   (if (number? top-int)
;                                       (abs (- top-int (- (* input input input) (* 2 input input) input)))
;                                       1000)))))
;          #:atom-generators (list (lambda () (random 10))
;                                  'in
;                                  'integer./
;                                  'integer.*
;                                  'integer.-
;                                  'integer.+
;                                  'integer.dup)
;          #:trivial-geography-radius 10)

;;;;;;;;;;;;
;; Same thing (without error scaling and without trivial geography) but with floats. This 
;; can easily come close but fail if early good programs rely on constants.

;(define-registered in (lambda (state) (push (stack-ref 'auxiliary 0 state) 'float state)))
;
;(schushgp #:error-function (lambda (program) 
;                             (for/list ((input (in-range 10)))
;                               (let ((state (make-schush-state)))
;                                 (push (* 1.0 input) 'float state)
;                                 (push (* 1.0 input) 'auxiliary state)
;                                 (run-schush program state)
;                                 (let ((top-float (top 'float state)))
;                                   (if (number? top-float)
;                                       (abs (- top-float (- (* input input input) (* 2.0 input input) input)))
;                                       1000)))))
;          #:atom-generators (list (lambda () (* 10.0 (random)))
;                                  'in
;                                  'float./
;                                  'float.*
;                                  'float.-
;                                  'float.+
;                                  'float.dup))

;;;;;;;;;;;;
;;; The ODD problem with an input instruction and everything else too.
;
;(define-registered in (lambda (state) (push (stack-ref 'auxiliary 0 state) 'integer state)))
;
;(schushgp #:error-function (lambda (program) 
;                             (for/list ((input (in-range 10)))
;                               (let ((state (make-schush-state)))
;                                 (push input 'integer state)
;                                 (push input 'auxiliary state)
;                                 (run-schush program state)
;                                 (let ((top-bool (top 'boolean state)))
;                                   (if (not (equal? top-bool 'no-stack-item))
;                                       (if (equal? top-bool (odd? input)) 0 1)
;                                       1000)))))
;          #:atom-generators (append registered-instructions
;                                    (list (lambda () (random 100))
;                                          (lambda () (random))
;                                          'in)))

;;;;;;;;;;;;
;; Integer symbolic regression of factorial, using an input instruction and lots of
;; other instructions. Hard but solvable. 
;
;(define-registered in (lambda (state) (push (stack-ref 'auxiliary 0 state) 'integer state)))
;
;(define factorial 
;  (lambda (n)
;    ;; Returns the factorial of n. 
;    (if (< n 2)
;        1
;        (* n (factorial (- n 1))))))
;
;(schushgp #:error-function (lambda (program) 
;                             (for/list ((input (in-range 1 6)))
;                               (let ((state (make-schush-state)))
;                                 (push input 'integer state)
;                                 (push input 'auxiliary state)
;                                 (run-schush program state)
;                                 (let ((top-int (top 'integer state)))
;                                   (if (number? top-int)
;                                       (abs (- (factorial input) top-int))
;                                       1000000000))))) ;; make the penalty big since the errors can be big
;          #:atom-generators (append (registered-for-type 'integer)
;                                    (registered-for-type 'exec)
;                                    (registered-for-type 'boolean)
;                                    (list (lambda () (random 100))
;                                          'in))
;          #:max-points 100)

;;;;;;;;;;;;
;; Same thing but with error scaling 
;
;(define-registered in (lambda (state) (push (stack-ref 'auxiliary 0 state) 'integer state)))
;
;(define factorial 
;  (lambda (n)
;    ;; Returns the factorial of n. 
;    (if (< n 2)
;        1
;        (* n (factorial (- n 1))))))
;
;(schushgp #:error-function (lambda (program) 
;                             (for/list ((input (in-range 1 6)))
;                               (let ((state (make-schush-state)))
;                                 (push input 'integer state)
;                                 (push input 'auxiliary state)
;                                 (run-schush program state)
;                                 (let ((top-int (top 'integer state)))
;                                   (if (number? top-int)
;                                       (abs (- (factorial input) top-int))
;                                       1000000000))))) ;; make the penalty big since the errors can be big
;          #:atom-generators (append (registered-for-type 'integer)
;                                    (registered-for-type 'exec)
;                                    (registered-for-type 'boolean)
;                                    (list (lambda () (random 100))
;                                          'in))
;          #:max-points 100
;          #:scale-errors #t)

;;;;;;;;;;;;
;; Same thing (without error scaling) but with compensatory mate selection
;
;(define-registered in (lambda (state) (push (stack-ref 'auxiliary 0 state) 'integer state)))
;
;(define factorial 
;  (lambda (n)
;    ;; Returns the factorial of n. 
;    (if (< n 2)
;        1
;        (* n (factorial (- n 1))))))
;
;(schushgp #:error-function (lambda (program) 
;                             (for/list ((input (in-range 1 6)))
;                               (let ((state (make-schush-state)))
;                                 (push input 'integer state)
;                                 (push input 'auxiliary state)
;                                 (run-schush program state)
;                                 (let ((top-int (top 'integer state)))
;                                   (if (number? top-int)
;                                       (abs (- (factorial input) top-int))
;                                       1000000000))))) ;; make the penalty big since the errors can be big
;          #:atom-generators (append (registered-for-type 'integer)
;                                    (registered-for-type 'exec)
;                                    (registered-for-type 'boolean)
;                                    (list (lambda () (random 100))
;                                          'in))
;          #:max-points 100
;          #:compensatory-mate-selection #t)
;(define-registered in (lambda (state) (push (stack-ref 'auxiliary 0 state) 'integer state)))
; (let ((s (make-schush-state)))
;   (run-schush '(1 2 integer.+) s)
;   (top 'integer s))



(require (planet soegaard/math:1:4/math))  
(define-registered in (lambda (state) (push (stack-ref 'auxiliary 0 state) 'integer state)))

(define count-elem
  (lambda (e l)
    (cond
     ((null? l) 0)
     ((equal? e (car l))
      (+ 1 (count-elem e (cdr l))))
     (else (count-elem e (cdr l))))))


(define value-list '())			   
(define is-prime-list '())
(define prime-range 50)


			     (for/list ([input (in-range prime-range)])
				       (let* ((state (make-schush-state)))
					 (push input 'integer state) ;; push integers from range onto stack 
					 (push input 'auxiliary state)
					 (run-schush
'(((integer.+ integer.- integer.- (integer./ in) in) integer.+ integer./ (integer.+) 4) integer.+ (integer.* (9 integer.* (integer.+ (5 integer.+ (integer.-))) integer.+ (integer./ 1)) integer./) (integer.* (integer./ (((integer./ in) in) integer.* in) integer.+) integer.+) (integer.+ integer.+))

;; '(((integer.- (1 integer.+ integer.- integer.* in) ((integer.* integer.-) integer.*) integer.+) integer.+ (integer./) integer.* (4)) 9 5 (integer.* (integer.- integer.-) ((integer.+) integer.-)) integer.+)


state)

				       (set! value-list (cons (top 'integer state) value-list))
				       (set! is-prime-list (cons (prime? (top 'integer state)) is-prime-list))
				       )
				       
				       )
				       (fprintf (current-output-port)
						"~n values: ~a  ~n primes: ~a ~n # non-primes: ~a ~n"
						(reverse value-list) (reverse is-prime-list) (count-elem #f is-prime-list))
;;

;;n^2 + n + 41

(define euler-list '())

(fprintf (current-output-port)
	 "values of n^2 + n + 41: ~n")

(for ([i (in-range prime-range)])
     (set! euler-list (cons (+ (square i) i 41) euler-list))
)
(fprintf (current-output-port)
	 "~a ~n" (reverse euler-list))



;;;; below works 

;; (require (planet soegaard/math:1:4/math))  
;; (define-registered in (lambda (state) (push (stack-ref 'auxiliary 0 state) 'integer state)))

;; (define value-list '())			   
;; (define is-prime-list '())


;; 			     (for/list ([input (in-range 20)])
;; 				       (let* ((state (make-schush-state)))
;; 					 (push input 'integer state) ;; push integers from range onto stack 
;; 					 (push input 'auxiliary state)
;; 					 (run-schush
;; 					  '((((2) (integer.+ 3) in) integer.+ integer.*) (((integer.* 3 integer.*) integer./ (6 4 integer.+ (integer.+ integer./)) integer.*) (9 integer.+ integer.*) (integer.+ integer.+ ((integer.+)))) integer.* (4) integer.+) state)
					 

;; 				       (set! value-list (cons (top 'integer state) value-list))
;; 				       (set! is-prime-list (cons (prime? (top 'integer state)) is-prime-list))
;; 				       )
;; 				        (fprintf (current-output-port)
;; 				        		"~n values: ~a  ~n primes: ~a"
;; 				        		value-list is-prime-list)


;; )

