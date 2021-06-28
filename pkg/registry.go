package registry

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"math"
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

func fromBytes(b []byte, t reflect.Kind) interface{} {
	switch t {
	case reflect.Bool:
		return b[0] == 1
	case reflect.Int:
		return int(fromBytes(b, reflect.Uint).(uint))
	case reflect.Int8:
		return int8(b[0])
	case reflect.Int16:
		return int16(binary.LittleEndian.Uint16(b))
	case reflect.Int32:
		return int32(binary.LittleEndian.Uint32(b))
	case reflect.Int64:
		return int64(binary.LittleEndian.Uint64(b))
	case reflect.Uint:
		if bits.UintSize == 64 {
			return uint(binary.LittleEndian.Uint64(b))
		}

		return binary.LittleEndian.Uint32(b)
	case reflect.Uint8:
		return uint8(b[0])
	case reflect.Uint16:
		return binary.LittleEndian.Uint16(b)
	case reflect.Uint32:
		return binary.LittleEndian.Uint32(b)
	case reflect.Uint64:
		return binary.LittleEndian.Uint64(b)
	case reflect.Float32:
		return math.Float32frombits(binary.LittleEndian.Uint32(b))
	case reflect.Float64:
		return math.Float64frombits(binary.LittleEndian.Uint64(b))
	case reflect.Complex64:
		var v complex64
		buf := bytes.NewReader(b)
		err := binary.Read(buf, binary.LittleEndian, &v)

		if err != nil {
			panic(err)
		}

		return v
	case reflect.Complex128:
		var v complex128
		buf := bytes.NewReader(b)
		err := binary.Read(buf, binary.LittleEndian, &v)

		if err != nil {
			panic(err)
		}

		return v
	case reflect.String:
		return string(b)
	default:
		panic(fmt.Sprintf("registry.fromBytes: not implemented for %#v", t))
	}
}

func toDword(vIn interface{}) uint32 {
	if v, ok := vIn.(int); ok {
		if v > math.MaxInt32 {
			panic(fmt.Sprintf("registry.toDword: value %d larger than %d", v, math.MaxInt32))
		} else if v < math.MinInt32 {
			panic(fmt.Sprintf("registry.toDword: value %d smaller than %d", v, math.MinInt32))
		}

		vIn = uint(v)
	}

	if v, ok := vIn.(uint); ok {
		if v > math.MaxUint32 {
			panic(fmt.Sprintf("registry.toDword: value %d larger than %d", v, math.MaxUint32))
		} else {
			vIn = uint32(v)
		}
	}

	switch v := vIn.(type) {
	case bool:
		if v {
			return 1
		} else {
			return 0
		}
	case int8:
		return uint32(v)
	case int16:
		return uint32(v)
	case int32:
		return uint32(v)
	case uint8:
		return uint32(v)
	case uint16:
		return uint32(v)
	case uint32:
		return v
	case float32:
		return fromBytes(toBytes(v), reflect.Uint32).(uint32)
	default:
		panic(fmt.Sprintf("registry.toDword: not implemented for %T", reflect.TypeOf(v).Kind()))
	}
}

func fromDword(v uint32, t reflect.Kind) interface{} {
	switch t {
	case reflect.Bool:
		return v == 1
	case reflect.Int:
		return int(v)
	case reflect.Int8:
		return int8(v)
	case reflect.Int16:
		return int16(v)
	case reflect.Int32:
		return int32(v)
	case reflect.Uint:
		return uint(v)
	case reflect.Uint8:
		return uint8(v)
	case reflect.Uint16:
		return uint16(v)
	case reflect.Uint32:
		return uint32(v)
	case reflect.Float32:
		return fromBytes(toBytes(v), reflect.Float32).(float32)
	default:
		panic(fmt.Sprintf("registry.fromDword: cannot convert to %#v", t))
	}
}

func toQword(vIn interface{}) uint64 {
	switch v := vIn.(type) {
	case bool:
		if v {
			return 1
		} else {
			return 0
		}
	case int:
		return uint64(v)
	case int8:
		return uint64(v)
	case int16:
		return uint64(v)
	case int32:
		return uint64(v)
	case int64:
		return uint64(v)
	case uint:
		return uint64(v)
	case uint8:
		return uint64(v)
	case uint16:
		return uint64(v)
	case uint32:
		return uint64(v)
	case uint64:
		return v
	case float32:
		return uint64(fromBytes(toBytes(v), reflect.Uint32).(uint32))
	case float64, complex64:
		return fromBytes(toBytes(v), reflect.Uint64).(uint64)
	default:
		panic(fmt.Sprintf("registry.toDword: not implemented for %T", reflect.TypeOf(v).Kind()))
	}
}

func fromQword(v uint64, t reflect.Kind) interface{} {
	switch t {
	case reflect.Bool:
		return v == 1
	case reflect.Int:
		return int(v)
	case reflect.Int8:
		return int8(v)
	case reflect.Int16:
		return int16(v)
	case reflect.Int32:
		return int32(v)
	case reflect.Int64:
		return int64(v)
	case reflect.Uint:
		return uint(v)
	case reflect.Uint8:
		return uint8(v)
	case reflect.Uint16:
		return uint16(v)
	case reflect.Uint32:
		return uint32(v)
	case reflect.Uint64:
		return uint64(v)
	case reflect.Float32:
		return fromBytes(toBytes(v), reflect.Float32).(float32)
	case reflect.Float64:
		return fromBytes(toBytes(v), reflect.Float64).(float64)
	case reflect.Complex64:
		return fromBytes(toBytes(v), reflect.Complex64).(complex64)
	default:
		panic(fmt.Sprintf("registry.fromQword: cannot convert to %#v", t))
	}
}

func toRegValue(vIn interface{}, regType uint32) reflect.Value {
	var valueOut reflect.Value

	switch regType {
	case registry.BINARY:
		return reflect.ValueOf(toBytes(vIn))
	case registry.DWORD:
		return reflect.ValueOf(toDword(vIn))
	case registry.QWORD:
		return reflect.ValueOf(toQword(vIn))
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
