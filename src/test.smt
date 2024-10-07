(declare-const x2_1 Int)
(declare-const x1_1 Int)
(assert (>= x2_1 1))
(assert (>= x1_1 1))
(assert (or
(<= 1 1)
))
(check-sat)
