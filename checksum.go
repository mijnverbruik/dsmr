package dsmr

import (
	"fmt"
	"strings"

	"github.com/snksoft/crc"
)

func verifyChecksum(t *Telegram, raw string, opts *parseOptions) error {
	// Only check footer if verifying is enabled and we found one while parsing
	if !opts.verifyChecksum || t.Footer.Value == "" {
		return nil
	}

	// Compute expected checksum from original message (including the "!" character).
	msg, _, _ := strings.Cut(raw, "!")
	checksum := fmt.Sprintf("%04X", crc.CalculateCRC(crc.CRC16, []byte(msg+"!")))

	if t.Footer.Value != checksum {
		return &ChecksumError{Unexpected: checksum, Expect: t.Footer.Value}
	}

	return nil
}
