package log

import (
	"bufio"
	"encoding/binary"
	"os"
	"sync"
)

var enc = binary.BigEndian

const lenWidth = 8 // 64-bits (uint64)

type store struct {
	File *os.File
	mu   sync.Mutex
	buf  *bufio.Writer
	size uint64
}

func newStore(f *os.File) (*store, error) {
	fi, err := os.Stat(f.Name())
	if err != nil {
		return nil, err
	}

	size := uint64(fi.Size())

	return &store{
		File: f,
		size: size,
		buf:  bufio.NewWriter(f),
	}, nil
}

// Append writes the contents of p into a store. It returns the total
// number of bytes written (n), the position where the store hold the
// index in its file (pos) and an error.
func (s *store) Append(p []byte) (n uint64, pos uint64, err error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	// pos is the end of the file where the record would be appended
	// to i.e the size of the entire file.
	pos = s.size

	// writing the length of the record into the first 8 bytes of the
	// buffer. This is constant so I guess records can have variable
	// lengths so we read the first 8 bytes to know how many bytes we
	// have to read.
	err = binary.Write(s.buf, enc, uint64(len(p)))
	if err != nil {
		return 0, 0, err
	}

	w, err := s.buf.Write(p)
	if err != nil {
		return 0, 0, err
	}

	w += lenWidth
	s.size += uint64(w)
	return uint64(w), pos, nil
}

// Read reads the record at the offset pos of a given record. It returns
// a byte slice of the record and an error
func (s *store) Read(pos uint64) ([]byte, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if err := s.buf.Flush(); err != nil {
		return nil, err
	}

	size := make([]byte, lenWidth)
	_, err := s.File.ReadAt(size, int64(pos))
	if err != nil {
		return nil, err
	}

	b := make([]byte, enc.Uint64(size))
	_, err = s.File.ReadAt(b, int64(pos+lenWidth))
	if err != nil {
		return nil, err
	}

	return b, nil
}

func (s *store) ReadAt(p []byte, off int64) (int, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if err := s.buf.Flush(); err != nil {
		return 0, err
	}

	return s.File.ReadAt(p, off)
}

func (s *store) Close() error {
	s.mu.Lock()
	defer s.mu.Unlock()

	err := s.buf.Flush()
	if err != nil {
		return err
	}

	return s.File.Close()
}

func (s *store) Name() string {
	return s.File.Name()
}
