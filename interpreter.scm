(define interpreter (lambda ()
    (repl (make-init-env)) ;; Run REPL with initial (empty) environment
))

(define repl (lambda (env)
    (let* (
        (dummy-input (display "repl> "))   
        (expr (read)) 
        ;; First handle environment updates for define statements
        (new-env 
            (if (define? expr)
                (let ((var (cadr expr))
                      (val-expr (caddr expr)))
                    (extend-env var (interpret val-expr env) env))
                env))
        ;; Then determine what to display
        (val
            (cond
                ( (define? expr) (cadr expr) )
                ;; Add here for lambda expr
                ( else (interpret expr env) )
            )
        )
        (dummy-print (display "repl: "))  
        (dummy-print2 
            (if (procedure-val? val) ;; If returned val is closure
                (display "[PROCEDURE]")
                (display val)
            )
        )
        ;; Prepare for the next prompt
        (dummy-new  (newline))
        (dummy-new2 (newline))
        )
        (repl new-env)
    )
))

;; Main interpreter
(define interpret (lambda (expr env)
    (cond
        ;; If number, eval to number
        ( (number? expr) expr )
        ;; If identifier, look for binding
        ( (symbol? expr) (lookup expr env) )
        ;; If let statement, 
        ( (let? expr env) 
            (if (eq? (check-duplicate-free (cadr expr)) #t) 
                (interpret-let expr env)                  ;; If no duplicate, interpret
                (go-back env)                             ;; If there is a duplicate, go back
            )
        )
        ;; If lambda statement,
        ( (lambda? expr env) (create-closure-from-lambda expr env) )
        ;; If an arithmetic operation
        ( (arithmetic-operation? expr) (interpret-arithmetic expr env) )        
        ;; If custom procedure application 
        ( (application? expr env) (interpret-application expr env) )

        ( else (go-back env) ) 
    )
))

(define go-back (lambda (env)
    (display "repl: ERROR")
    (newline)
    (newline)
    (repl env)
))

(define expr? (lambda (expr env)
    (or
        ( number? expr )            ;; Numbers
        ( symbol? expr)   ;; Identifier
        ( let? expr env )               ;; Let expression           
        ( lambda? expr env )            ;; Lambda expression
        ( arithmetic-operation? expr )
        ( application? expr env )       ;; Application expression 
    )
))

(define arithmetic-operation? (lambda (expr)
    (and (list? expr)
         (not (null? expr))
         (member (car expr) '(+ - * /))
    )         
))

(define interpret-arithmetic (lambda (expr env)
    (let( (op (get-arithmetic (car expr)))
          (operands (map (lambda (x) (interpret x env)) (cdr expr))) )
        (apply op operands)
    )
))

(define get-arithmetic (lambda (op-symbol)
    (cond
        ;; Returns the corresponding procedure value 
        ( (equal? op-symbol '+) +)
        ( (equal? op-symbol '-) -)
        ( (equal? op-symbol '*) *)
        ( (equal? op-symbol '/) /)
    )
))

;; -----------------------
;; DEFINE
;; -----------------------
(define define? (lambda (expr)
    (and    ;; ( define IDENT <expr> )
        ( list? expr )
        ( = (length expr) 3 )
        ( eq? (car expr) 'define )
        ( symbol? (cadr expr) )
    )
))

(define is-defined (lambda (var env)
    (cond 
        ( (null? env) #f )                  ;; If traverse finished return false
        ( (eq? var (caar env)) #t )         ;; If matches, return #t
        ( else (is-defined var (cdr env)))  ;; Else, search in rest of env
    )
))

(define lookup (lambda (var env)
    (cond 
        ( (eq? (is-defined var env) #f) (go-back env) ) ;; If not defined in the env, go back
        ( (eq? var (caar env)) (cdar env) )                        ;; If match, return its value
        ( else (lookup var (cdr env)))               ;; If no match, try the rest of env
    )
))

;; -----------------------
;; LET
;; -----------------------
(define let? (lambda (expr env)
    (and    ;; ( let ( <var_binding_list> ) <expr> )
        ( list? expr )
        ( = (length expr) 3 )
        ( eq? (car expr) 'let )
        ( valid-binding-list? (cadr expr) env )   ;; Second element must be var_binding_list
    )
))

(define valid-binding-list? (lambda (bindings env)
    (cond   ;; ( var1 expr1 ) ( var2 expr2 ) ...
        ( (null? bindings) #t )                             ;; Empty binding list is valid
        ( (not (pair? (car bindings))) (go-back env) )      ;; Each binding must be a pair
        ( (not (= (length (car bindings)) 2)) (go-back env) )
        ( (not (symbol? (caar bindings))) (go-back env) )   ;; Each var must be a symbol 
        ( (not (expr? (cadar bindings) env)) (go-back env) )    ;; Each val must be an expr
        ( else (valid-binding-list? (cdr bindings) env) )    ;; Check rest of bindings
    )
))

(define check-duplicate-free (lambda (bindings)
    (cond
        ((null? bindings) #t)                              ; Empty list has no duplicates
        ((null? (cdr bindings)) #t)                        ; Single binding has no duplicates
        ((is-in-rest? (caar bindings) (cdr bindings)) #f)  ; Check if first var appears in rest
        (else (check-duplicate-free (cdr bindings)))       ; Check rest of bindings
    )
))

(define is-in-rest? (lambda (var bindings)
    (cond
        ((null? bindings) #f)                           ; Not found in rest
        ((eq? var (caar bindings)) #t)                  ; Found duplicate
        (else (is-in-rest? var (cdr bindings)))         ; Check rest of bindings
    )
))

(define build-local-env (lambda (bindings old-env temp-env)
    (cond
        ((null? bindings) temp-env)                            ; Return completed temp env
        (else 
            (let ((var (caar bindings))                        ; Get variable name
                  (val (interpret (cadar bindings) old-env)))  ; Evaluate expression in OLD env
                (if (eq? val 'error)
                    (go-back old-env)                     ; Propagate any errors
                    (build-local-env 
                        (cdr bindings)                         ; Rest of bindings
                        old-env                                ; Keep original env for evaluating
                        (extend-env var val temp-env)          ; Add to temp env
                    )
                )
            )
        )
    )
))

(define interpret-let (lambda (expr env)
    (let* (
        (bindings (cadr expr))              ; Get the bindings list
        (body (caddr expr))                 ; Get the body expression
        (temp-env                           ; Build temporary environment
            (build-local-env bindings env '())) ;; with an empty temporary environment 
    )
        (if (eq? temp-env 'error-occured-while-interpreting-let)
            'error-occured-while-interpreting-let                ; Propagate any errors from binding evaluation
            (interpret body                 ; Evaluate body in combined environment
                (append temp-env env))      ; Temporary bindings override global ones
        )
    )
))

;; -----------------------
;; LAMBDA
;; -----------------------
(define lambda? (lambda (expr env)
    (and
        (list? expr)                ;; Must be a list
        (= (length expr) 3)         ;; with length 3
        (equal? (car expr) 'lambda) ;; with 'lambda first element
        (check-valid-param-list (cadr expr) env) ;; Check if param list is valid
        (expr? (caddr expr) env)            ;; Check if body is expr
    )
))

;; Check if it's a list and if each item in the param list is identifier
(define check-valid-param-list (lambda (param-list env)
    (if (list? param-list) 
        (cond 
            ( (null? param-list) #t )
            ( (not (symbol? (car param-list))) (go-back env) )
            ( else (check-valid-param-list (cdr param-list) env) )
        )
        (go-back env)
    )
))

;; It returns a closure, which stores the procedure info
(define create-closure-from-lambda (lambda (expr env)
    (make-closure (cadr expr)   ;; param-list
                (caddr expr)    ;; body expression
                env             ;; current environment 
    )
))

;; closure format: (closure params body env)
;; e.g. (closure (x) (+ x 2) env)
(define make-closure (lambda (params body env)
    (list 'closure params body env)
))

; Helper to check if value is a procedure
(define procedure-val? (lambda (val)
    (and (list? val)
         (not (null? val))
         (eq? (car val) 'closure))
))

(define apply-closure (lambda (closure args env)
    (let ( (params (cadr closure)) 
          (body (caddr closure))
          (saved-env (cadddr closure)) )
        ;; Create new environment with parameters bound to arguments
        (let ( (new-env (extend-env-multiple params args saved-env)) )
            ;; Evaluate body in new environment
            (interpret body new-env)
        )
    )
))

;; Helper to extend environment with multiple bindings
(define extend-env-multiple (lambda (vars vals env)
    (if (null? vars)
        env
        (extend-env-multiple 
            (cdr vars)
            (cdr vals)
            (extend-env (car vars) (car vals) env))
    )
))

;; e.g. (addtwo 2 4)
(define application? (lambda (expr env)
    (cond
        ( (lambda? expr env) #t ) 
        ( (symbol? (car expr)) 
            (procedure-val? (lookup (car expr) env))
        )
    )
))

;; e.g. (addtwo 2 4)
(define interpret-application (lambda (expr env)
    (if (symbol? (car expr))
        (let* ( (proc (car expr)) (proc-val (lookup (car expr) env)) (arg-list (cdr expr)) )
            (if (= (length (cadr proc-val)) (length arg-list))
                (apply-closure proc-val arg-list env)
                (go-back env)  
            )
        )
        (if (lambda? (car expr) env)
            (let* ( (proc (car expr)) (proc-val (create-closure-from-lambda proc env)) (arg-list (cdr expr)) )
                (if (= (length (cadr proc-val)) (length arg-list))
                    (apply-closure proc-val arg-list env)
                    (go-back env) 
                )   
            )
            ;; Otherwise give error
            (go-back env)
        )        
    )
))


;; -----------------------
;; ENVIRONMENT
;; -----------------------
(define make-init-env (lambda ()
    '() ;; Start with an empty environment
))

;; Helper to find and update a variable binding
(define update-binding (lambda (var val env)
    (cond 
        ((null? env) #f)                           ; Not found
        ((eq? var (caar env))                      ; Found the variable
            (cons (cons var val) (cdr env)))       ; Update its value
        (else                                      ; Keep searching
            (let ((rest-env (update-binding var val (cdr env))))
                (if rest-env
                    (cons (car env) rest-env)      ; Propagate the update
                    #f))))                         ; Not found in this branch
))                        
;; Extend or update existing environment when a new define statement is given 
(define extend-env (lambda (var val old-env)
    (let ((updated-env (update-binding var val old-env)))
        (if updated-env
            updated-env                            ; Use updated environment if found
            (cons (cons var val) old-env)))))      ; Otherwise add new binding