package registry

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"math/bits"
	"reflect"

	"golang.org/x/sys/windows/registry"
)

func toBytes(vIn interface{}) []byte {
	if v, ok := vIn.(int); ok {
		vIn = uint(v)
	}

	if v, ok := vIn.(uint); ok {
		if bits.UintSize == 64 {
			vIn = uint64(v)
		} else {
			vIn = uint32(v)
		}
		}

	switch v := vIn.(type) {
	case bool, int8, int16, int32, int64, uint8, uint16, uint32, uint64, float32, float64, complex64, complex128:
		buf := new(bytes.Buffer)
		err := binary.Write(buf, binary.LittleEndian, v)

		if err != nil {
			panic(err)
		}

		return buf.Bytes()
	case string:
		return []byte(v)
	default:
		panic(fmt.Sprintf("registry.toBytes: not implemented for type %T", v))
	}
}

func toRegValue(vIn interface{}, regType uint32) reflect.Value {
	var valueOut reflect.Value

	switch regType {
	case registry.BINARY:
		return reflect.ValueOf(toBytes(vIn))
	case registry.DWORD:
	case registry.QWORD:
	case registry.SZ:
	case registry.MULTI_SZ:
	case registry.EXPAND_SZ:
	}

	return valueOut
}

func Load(kData interface{}, key registry.Key, path string) {
	// k, err := registry.OpenKey(registry.CLASSES_ROOT, "SOFTWARE\\Clients\\SearchDeflector\\Test", registry.WRITE)

	// registry
}

func Write(kData interface{}, key registry.Key, path string) {

}
