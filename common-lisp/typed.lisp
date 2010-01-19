(defpackage :gp.typed
  (:use :cl
        :utils
        :gp)
  (:shadow type
           function
           variable
           constant
           root))

(in-package :gp.typed)

(export 'create-typed-grammar)
(export 'crossover)
(export 'point-mutation)

(defclass typed-individual (gp-individual tree-representation)
  ((grammar
    :initarg :grammar
    :initform (error "Grammar attribute unbound.")
    :reader grammar)))

(defclass typed-grammar ()
  ((root
    :initarg :root
    :initform (error "Root type unknown")
    :reader root)
   (constants
    :initarg :constants
    :initform (error "Terminals list unbound")
    :reader constants)
   (functions
    :initarg :functions
    :initform (error "Functions list unbound")
    :reader functions)
   (variables
    :initarg :variables
    :initform ()
    :reader variables)   
  (types
    ;; TODO: Posiblemente ese hash puede llevar :test #'eq
    :initform (make-hash-table))))

(defmethod get-type ((grammar typed-grammar) type)
  (let ((ret (gethash type (slot-value grammar 'types))))
    (or ret
        (setf (gethash type (slot-value grammar 'types))
              (make-instance 'type)))))

(defclass type ()
  ((min-height
    :initform :infinite
    :initarg :min-height
    :accessor min-height)
   (generators
    :initform '()
    :initarg :generators
    :accessor generators)))

(defclass grammar-element ()
  ((expression
    :initarg :expression
    :reader expression)
   (type
    :initarg :type
    :reader type)
   (min-height
    :initform 1
    :accessor min-height)))

(defclass terminal (grammar-element)
  ((min-height
    :initform 1)))    

(defclass constant (terminal) ())

(defclass variable (terminal) ())

(defclass function (grammar-element)
  ((parameter-types
    :initarg :parameter-types
    :reader parameter-types)
   (min-height
    :initform :infinite)))   

(defmethod initialize-instance :after ((tg typed-grammar) &rest initargs)
  (declare (ignore initargs))
  (flet (
         (add-type-generators (expressions)
           (mapc (lambda (x) (push x (generators (get-type tg (type x)))))
                 expressions))

         ;; La altura minima bajo una funcion es el maximo de las alturas minimas de los tipos de sus parametros
         (calc-func-heights-from-type-heights ()
           (let ((something-changed nil))
             (mapc (lambda (f)
                     (when (eq (min-height f) :infinite)
                       (let ((new-min-height (reduce #'extended-max/2 (parameter-types f) :key #'(lambda (_type) (min-height (get-type tg _type)) ) :initial-value 0)))
                         (when (not (eq new-min-height :infinite))                           
                           (setf (min-height f) (1+ new-min-height))
                           (setf something-changed t)))))
                   (functions tg))
             something-changed))

         ;; La altura minima bajo un tipo es el minimo de las alturas minimas de las funciones que lo generan
         (calc-type-heights-from-function-heights ()
           (let ((something-changed nil))
             (maphash (lambda (_type type-data)
                        (declare (ignorable _type))
                        (when (eq (min-height type-data) :infinite)
                          (let ((new-min-height (reduce #'extended-min/2 (generators type-data) :key #'min-height :initial-value :infinite)))
                            (when (not (eq new-min-height :infinite))
                              (setf (min-height type-data) new-min-height)
                              (setf something-changed t)))))
                      (slot-value tg 'types))
             something-changed)))                           

    ;; Asociar las funciones con los tipos que generan
    (add-type-generators (functions tg))
    ;; Asociar las constantes con los tipos que generan
    (add-type-generators (constants tg))
    ;; Asociar las variables con los tipos que generan
    (add-type-generators (variables tg))

    ;; Iterar calculando las alturas minimas de las funciones y de los tipos hasta que en una iteración no cambie nada. Si eso ocurre es que no se van a propagar mas alturas.
    (loop
       for b = (calc-type-heights-from-function-heights)
       for a = (calc-func-heights-from-type-heights)
       while (or a b))

    ;; Lanzar error si la raiz no se puede desarrollar
    (when (infinitep (min-height (get-type tg (root tg))))
              (error "Root type ~A can not be generated. There is no path from root to terminal elements." (root tg)))

    ;; Lanzar warnings para tipos y funciones no desarrollables
    ;; Además son borrados de los tipos que no se pueden desarrollar de forma finita, de esa forma se facilita la creacion de arboles
    (maphash (lambda (_type type-data)
               ;;Si el tipo no se puede crear, se avisa y se borra
               (when (infinitep (min-height type-data))
                 (remhash _type (slot-value tg 'types))                                                    
                 (warn "Type ~A can not be generated. Will not be used." _type))
               ;;Si alguna funcion que genera el tipo no se puede crear, se avisa y se borra.
               (mapc (lambda (x) (when (infinitep (min-height x))
                              (warn "Function ~A will not be used. Imposible to generate a finite subtree." (expression x))))
                     (generators type-data))
               (delete-if #'infinitep (generators type-data) :key #'min-height))
             (slot-value tg 'types))
    
    ;; Ordenar los generadores de un tipo por orden decreciente de altura mínima. Facilita la creacion de arboles
    (maphash (lambda (_type type-data)
               (declare (ignore _type))
               (setf (generators type-data)
                     (sort (generators type-data) #'> :key #'min-height)))
             (slot-value tg 'types))))

(defmethod max-height-generators ((type type) max-height)
  "Devuelve todas las posibles formas de generar un nodo del tipo type de manera que el subarbol tenga una altura menor que max-height"
  (labels ((max-height-generators (ordered-generators max-height)
             (if (or (null ordered-generators)
                     (<= (min-height (first ordered-generators)) max-height))
                 ordered-generators
                 (max-height-generators (cdr ordered-generators) max-height))))
    (max-height-generators (generators type) max-height)))

;; Generar un arbol con tipo aleatorio teniendo como raiz una expresion de ese tipo
(defmethod create-random-tree ((root type) (grammar typed-grammar) max-height)
  (let ((generators (max-height-generators root max-height)))
    (create-random-tree (select-randomly generators) grammar max-height)))

(defmethod create-random-tree ((root constant) (grammar typed-grammar) max-height)
  (declare (ignore max-height grammar))
  (cons (if (cl:functionp (expression root))
            (make-instance 'constant
                           :expression (funcall (expression root))
                           :type (type root))
            root)
        nil))

(defmethod create-random-tree ((root variable) (grammar typed-grammar) max-height)
  (declare (ignore max-height grammar))
  (cons root nil))

(defmethod create-random-tree ((root function) (grammar typed-grammar) max-height)
  (cons  root
         (mapcar #'(lambda (type)
                     (create-random-tree (get-type grammar type) grammar (1- max-height)))
                 (parameter-types root))))

(defmethod create-random-individual ((grammar typed-grammar) max-height)
  (make-instance 'typed-individual
                 :grammar grammar
                 :tree (create-random-tree (get-type grammar (root grammar))
                                    grammar
                                    max-height)))

(defmethod s-expr((x terminal) children-s-expr)
  (declare (ignore children-s-expr))
  (expression x))

(defmethod s-expr((x function) children-s-expr)
  (cons (expression x) children-s-expr))

(defmethod individual->s-expr ((ind typed-individual))
  (list 'lambda
        (mapcar #'expression (variables (grammar ind)))
        (reduce-tree #'s-expr
                     ;;; (lambda (label st)
;;;                          (if (and (null st)
;;;                                   (not (typep label 'function)))
;;;                              (expression label)
;;;                              (cons (expression label) st)))
                     #'cons
                     nil
                     (tree ind))))

(defmethod print-object ((ind typed-individual) stream)
  (format stream "~A" (individual->s-expr ind)))

(defmethod as-a-function ((individual typed-individual))
  (eval (individual->s-expr individual)))

;; Macro para crear gramaticas tipadas con una sintaxis agradable
(defun process-constant (x)
  `(make-instance 'constant
                  :expression ,(first x)
                  :type ,(second x)))

(defun process-variable (x)
  `(make-instance 'variable
                  :expression ',(first x)
                  :type ,(second x)))

(defun process-function (x)
  `(make-instance 'function
                  :expression ',(first x)
                  :type ,@(last x)
                  :parameter-types ',(subseq x 1 (1- (length x)))))

;; (create-typed-grammar
;;  :root :float
;;  :constants ((#'(lambda () (random 1.0)) :float))
;;  :functions ((+ :float :float :float)
;;              (* :float :float :float)
;;              (if :boolean :float :float :float)
;;              (< :float :float :boolean)
;;              (> :float :float :boolean))             
;;  :variables ((x :float)
;;              (y :float)))
(defmacro create-typed-grammar (&key root (constants ()) functions (variables ()))
  `(make-instance 'typed-grammar
                  :root ,root
                  :constants (list ,@(mapcar #'process-constant constants))
                  :functions (list ,@(mapcar #'process-function functions))
                  :variables (list ,@(mapcar #'process-variable variables))
                  ))

(defmethod all-types-in ((individual typed-individual))
  (reduce-tree #'(lambda (label st)
                   (pushnew (type label) st))
               #'nunion
               nil
               (tree individual)))

;; OPERADOR DE CRUCE
(defclass crossover (operator)
  ((number-of-parents
    :initform 2)
   (number-of-children
    :initform 2)))

;; (def-print-object crossover '(max-size max-height))

(defmethod apply-operator ((op crossover) &rest parents)
  (let* ((ind1 (first parents))
         (ind2 (second parents))
         (child1 (cons 'dummy (list (copy-tree (tree ind1)))))
         (child2 (cons 'dummy (list (copy-tree (tree ind2)))))
         (common-types (intersection (all-types-in ind1)
                                     (all-types-in ind2)))
         (crossover-point1  (random-subtree-parent child1
                                                   :filter #'(lambda (x) (find (type x) common-types :test #'eq))))
         ;; Si es una llamada a una funcion, el tipo es el tipo de retorno de la funcion. Si no el tipo del terminal
         (point1-type (type (caar crossover-point1)))
         (crossover-point2 (random-subtree-parent child2
                                                  :filter #'(lambda (x) (eq (type x) point1-type)))))
    (exchange (first crossover-point1)
              (first crossover-point2))

    ;; Evidentemente heredan la gramatica
    (list  (make-instance 'typed-individual :grammar (grammar ind1) :tree (second child1))
	   (make-instance 'typed-individual :grammar (grammar ind1) :tree (second child2)))))

;; OPERADOR DE MUTACION PUNTUAL
(defclass point-mutation (operator)
  ((number-of-parents
    :initform 1)
   (number-of-children
    :initform 1)))

(defmethod apply-operator ((op point-mutation) &rest parents)
  (let* ((parent (first parents))
         (grammar (grammar parent))
         (child-tree (copy-tree (tree parent)))
         (subtree (random-subtree child-tree)))
      ;; Si es una hoja se cambia por una hoja del mismo tipo
      (if (typep (first subtree) 'function)
          (let* ((parameter-types (parameter-types (first subtree)))
                 (type (type (first subtree)))
                 (generators (remove-if-not #'(lambda (x)
                                                (and (eql type (type x))
                                                     (equal parameter-types (parameter-types x))))                                                
                                            (functions grammar))))
            (setf (first subtree)
                  (select-randomly generators)))
          ;; Si es un terminal
          (setf (first subtree)
                (first (create-random-tree (get-type grammar (type (car subtree)))
                                           grammar
                                           1))))
      (list (make-instance 'typed-individual :grammar grammar :tree child-tree))))