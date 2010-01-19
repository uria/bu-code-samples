(in-package :gp)

(export 'tree-representation)
(export 'tree)

(export 'root)
(export 'children)
(export 'leafp)

(export 'reduce-tree)
(export 'random-subtree)
(export 'random-subtree-parent)

(export 'height)
(export 'size)

(export 'max-height)
(export 'max-size)

;; Utilidades para arboles
(defun label (tree)
  (car tree))

(defun children (tree)
  (cdr tree))

(defun leafp (tree)
  (null (children tree)))

;; fold de arboles
;; f es una funcion que recibe dos parametros, la etiqueta del nodo y el resultado de aplicar la funcion g al resultado de los subarboles
;; g reduce el resultado de unos subarboles, en caso de querer la lista usar #'cons
;; a es el parametro inicial al reducir la lista de subarboles (por tanto el segundo parametro de f cuando el nodo es una hoja)
;; TODO: cambiar first y rest por algo mas de jerga de arboles
(defun reduce-tree (f g a tree)
	   (funcall f 
		    (label tree)
		    (reduce g 
			    (children tree)
			    :key #'(lambda (st) (reduce-tree f g a st)) 
			    :initial-value a 
			    :from-end t)))

(defun postorder-tree (f g a tree)
  (funcall f
           tree
           (reduce g
                   (children tree)
                   :key #'(lambda (st) (postorder-tree f g a st)) 
                   :initial-value a 
                   :from-end t)))

(defun random-subtree (tree &key (filter #'always-t) (key #'first))
  (let ((subtrees (postorder-tree #'(lambda (tree st)
                                      (if (funcall filter (if (null key)
                                                              tree
                                                              (funcall key tree)))
                                          (cons tree st)
                                          st))                               
                                  #'append
                                  nil
                                  tree)))
    (select-randomly subtrees)))

;; se le suele pasar con un dummy al comienzo
;; se utiliza para poder hacer cruces facilmente intercambiando first y first de dos subarboles devueltos por esta funcion
;; TODO: Tal vez se pueda usar nconcig
(defun random-subtree-parent (tree &key (filter #'always-t))
  (labels ((subtrees-parents (tree)
             (loop for st on (cdr tree) appending (if (funcall filter (caar st))
                                                      (cons st
                                                            (subtrees-parents (first st)))
                                                      (subtrees-parents (first st))))))
    (select-randomly (subtrees-parents tree))))

;; 
;; Representacion basada en árboles
;; 
(defclass tree-representation (individual)
  ((tree :accessor tree 
	 :initarg :tree
	 :initform nil)))

(defmethod print-object ((ind tree-representation) stream)
  (write (tree ind)) stream)

(defmethod size ((ind tree-representation))
  (reduce-tree #'(lambda (l st)
                   (declare (ignore l))
                   (1+ st))
               #'+
               0
               (tree ind)))

(defmethod height ((ind tree-representation))
  (reduce-tree #'(lambda (l st)
                   (declare (ignore l))
                   (if (null st) 
                       0
                       (1+ (apply #'max st))))
               #'cons 
               nil 
               (tree ind)))

;; Restricciones para representaciones basadas en arboles. GP clasica
(defclass max-height (constraint)
  ((max-height
    :initarg :max-height)))

(def-print-object max-height '(max-height))

(defmethod test-constraint ((cons max-height) ind)
  (<= (height ind)
      (slot-value cons 'max-height)))

(defclass max-size (constraint)
  ((max-size
    :initarg :max-size)))

(def-print-object max-size '(max-size))

(defmethod test-constraint ((cons max-size) ind)
  (<= (size ind)
      (slot-value cons 'max-size)))
