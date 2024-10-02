package stack

import "errors"

type Stack[T comparable] struct {
	buffer []T
}

func InitStackString() *Stack[string] {
	return &Stack[string]{
		buffer: make([]string, 0),
	}
}

func (s *Stack[T]) Push(elem T) {
	s.buffer = append(s.buffer, elem)
}

func (s *Stack[T]) Pop() (T, error) {
	if len(s.buffer) > 0 {
		elem := s.buffer[len(s.buffer)-1]
		s.buffer = s.buffer[:len(s.buffer)-1]
		return elem, nil
	}
	var temp T
	return temp, errors.New("empty buffer")
}

func (s *Stack[T]) Back() (T, error) {
	if len(s.buffer) > 0 {
		elem := s.buffer[len(s.buffer)-1]
		return elem, nil
	}
	var temp T
	return temp, errors.New("empty buffer")
}

func (s *Stack[T]) Size() int {
	return len(s.buffer)
}

func (s *Stack[T]) Clear() {
	s.buffer = make([]T, 0)
}

func (s *Stack[T]) GetBufferStack() []T {
	return s.buffer
}
