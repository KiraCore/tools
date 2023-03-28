package cli

import (
	"context"
	"sync"
)

type InMemoryBlockStore struct {
	// any private fields the implementation requires
	data  map[string][]byte
	mutex sync.RWMutex
}

func (s *InMemoryBlockStore) Has(ctx context.Context, key string) (bool, error) {
	s.mutex.RLock()
	_, ok := s.data[key]
	s.mutex.RUnlock()
	return ok, nil
}

func (s *InMemoryBlockStore) Put(ctx context.Context, key string, content []byte) error {
	s.mutex.Lock()
	s.data[key] = content
	s.mutex.Unlock()
	return nil
}

func NewInMemoryBlockStore() *InMemoryBlockStore {
	return &InMemoryBlockStore{
		data: make(map[string][]byte),
	}
}
