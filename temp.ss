(define test-report1
  (lambda (population)
    (require (planet soegaard/math:1:4/math))  
    (define-registered in (lambda (state) (push (stack-ref 'auxiliary 0 state) 'integer state)))

    (define value-list '())			   
    (define is-prime-list '())
    (define prime-range 20)

    (for/list ([input (in-range prime-range)])
	      (let* ((state (make-schush-state)))
		(push input 'integer state) ;; push integers from range onto stack 
		(push input 'auxiliary state)
		(run-schush
		 '((((2) (integer.+ 3) in) integer.+ integer.*) (((integer.* 3 integer.*) integer./ (6 4 integer.+ (integer.+ integer./)) integer.*) (9 integer.+ integer.*) (integer.+ integer.+ ((integer.+)))) integer.* (4) integer.+) 

		 state)

		(set! value-list (cons (top 'integer state) value-list))
		(set! is-prime-list (cons (prime? (top 'integer state)) is-prime-list))
		)


	      (fprintf (current-output-port)
		       "~n values: ~a  ~n primes: ~a"
		       value-list is-prime-list)


	      )
    )
  ) 