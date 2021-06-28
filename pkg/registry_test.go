package registry

import (
	"math"
	"math/bits"
	"reflect"
	"testing"

	"github.com/stretchr/testify/assert"
)

type ExampleData struct {
	BoolValue       bool       `regName:"BoolValue"       regType:"BINARY"`
	IntValue        int        `regName:"IntValue"        regType:"BINARY"`
	Int8Value       int8       `regName:"Int8Value"       regType:"BINARY"`
	Int16Value      int16      `regName:"Int16Value"      regType:"BINARY"`
	Int32Value      int32      `regName:"Int32Value"      regType:"BINARY"`
	Int64Value      int64      `regName:"Int64Value"      regType:"BINARY"`
	UintValue       uint       `regName:"UintValue"       regType:"BINARY"`
	Uint8Value      uint8      `regName:"Uint8Value"      regType:"BINARY"`
	Uint16Value     uint16     `regName:"Uint16Value"     regType:"BINARY"`
	Uint32Value     uint32     `regName:"Uint32Value"     regType:"BINARY"`
	Uint64Value     uint64     `regName:"Uint64Value"     regType:"BINARY"`
	Float32Value    float32    `regName:"Float32Value"    regType:"BINARY"`
	Float64Value    float64    `regName:"Float64Value"    regType:"BINARY"`
	Complex64Value  complex64  `regName:"Complex64Value"  regType:"BINARY"`
	Complex128Value complex128 `regName:"Complex128Value" regType:"BINARY"`
	StringValue     string     `regName:"StringValue"     regType:"BINARY"`
}

var d ExampleData = ExampleData{
	BoolValue: true,
	IntValue: func() int {
		if bits.UintSize == 64 {
			return math.MinInt64
		}

		return math.MinInt32
	}(),
	Int8Value:  math.MinInt8,
	Int16Value: math.MinInt16,
	Int32Value: math.MinInt32,
	Int64Value: math.MinInt64,
	UintValue: func() uint {
		if bits.UintSize == 64 {
			return math.MaxUint64
		}

		return math.MaxUint32
	}(),
	Uint8Value:      math.MaxUint8,
	Uint16Value:     math.MaxUint16,
	Uint32Value:     math.MaxUint32,
	Uint64Value:     math.MaxUint64,
	Float32Value:    math.SmallestNonzeroFloat32,
	Float64Value:    math.SmallestNonzeroFloat64,
	Complex64Value:  complex64(complex(math.MaxFloat32, 1)),
	Complex128Value: complex(math.MaxFloat64, 1),
	StringValue:     "abcdefghijklmnopqrstuvwxyz",
}

func TestFromBytes(t *testing.T) {
	var v interface{}

	v = true
	assert.Equal(t, v, fromBytes(toBytes(v), reflect.Bool).(bool))
	v = false
	assert.Equal(t, v, fromBytes(toBytes(v), reflect.Bool).(bool))

	v = int(math.MaxInt16)
	assert.Equal(t, v, fromBytes(toBytes(v), reflect.Int).(int))
	v = int(math.MinInt16)
	assert.Equal(t, v, fromBytes(toBytes(v), reflect.Int).(int))

	v = int8(math.MaxInt8)
	assert.Equal(t, v, fromBytes(toBytes(v), reflect.Int8).(int8))
	v = int8(math.MinInt8)
	assert.Equal(t, v, fromBytes(toBytes(v), reflect.Int8).(int8))

	v = int16(math.MaxInt8)
	assert.Equal(t, v, fromBytes(toBytes(v), reflect.Int16).(int16))
	v = int16(math.MinInt8)
	assert.Equal(t, v, fromBytes(toBytes(v), reflect.Int16).(int16))

	v = int32(math.MaxInt32)
	assert.Equal(t, v, fromBytes(toBytes(v), reflect.Int32).(int32))
	v = int32(math.MinInt32)
	assert.Equal(t, v, fromBytes(toBytes(v), reflect.Int32).(int32))

	v = int64(math.MaxInt64)
	assert.Equal(t, v, fromBytes(toBytes(v), reflect.Int64).(int64))
	v = int64(math.MinInt64)
	assert.Equal(t, v, fromBytes(toBytes(v), reflect.Int64).(int64))

	v = uint(math.MaxUint16)
	assert.Equal(t, v, fromBytes(toBytes(v), reflect.Uint).(uint))

	v = uint8(math.MaxUint8)
	assert.Equal(t, v, fromBytes(toBytes(v), reflect.Uint8).(uint8))

	v = uint16(math.MaxUint16)
	assert.Equal(t, v, fromBytes(toBytes(v), reflect.Uint16).(uint16))

	v = uint32(math.MaxUint32)
	assert.Equal(t, v, fromBytes(toBytes(v), reflect.Uint32).(uint32))

	v = uint64(math.MaxUint64)
	assert.Equal(t, v, fromBytes(toBytes(v), reflect.Uint64).(uint64))

	v = float32(math.MaxFloat32)
	assert.Equal(t, v, fromBytes(toBytes(v), reflect.Float32).(float32))
	v = float32(math.SmallestNonzeroFloat32)
	assert.Equal(t, v, fromBytes(toBytes(v), reflect.Float32).(float32))

	v = float64(math.MaxFloat64)
	assert.Equal(t, v, fromBytes(toBytes(v), reflect.Float64).(float64))
	v = float64(math.SmallestNonzeroFloat64)
	assert.Equal(t, v, fromBytes(toBytes(v), reflect.Float64).(float64))

	v = complex64(complex(math.MaxFloat32, math.SmallestNonzeroFloat32))
	assert.Equal(t, v, fromBytes(toBytes(v), reflect.Complex64).(complex64))
	v = complex64(complex(math.SmallestNonzeroFloat32, math.MaxFloat32))
	assert.Equal(t, v, fromBytes(toBytes(v), reflect.Complex64).(complex64))

	v = complex128(complex(math.MaxFloat64, math.SmallestNonzeroFloat64))
	assert.Equal(t, v, fromBytes(toBytes(v), reflect.Complex128).(complex128))
	v = complex128(complex(math.SmallestNonzeroFloat64, math.MaxFloat64))
	assert.Equal(t, v, fromBytes(toBytes(v), reflect.Complex128).(complex128))

	v = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	assert.Equal(t, v, fromBytes(toBytes(v), reflect.String).(string))
}

func TestFromDword(t *testing.T) {
	var v interface{}

	v = true
	assert.Equal(t, v, fromDword(toDword(v), reflect.Bool).(bool))
	v = false
	assert.Equal(t, v, fromDword(toDword(v), reflect.Bool).(bool))

	v = int(math.MaxInt16)
	assert.Equal(t, v, fromDword(toDword(v), reflect.Int).(int))
	v = int(math.MinInt16)
	assert.Equal(t, v, fromDword(toDword(v), reflect.Int).(int))

	v = int8(math.MaxInt8)
	assert.Equal(t, v, fromDword(toDword(v), reflect.Int8).(int8))
	v = int8(math.MinInt8)
	assert.Equal(t, v, fromDword(toDword(v), reflect.Int8).(int8))

	v = int16(math.MaxInt8)
	assert.Equal(t, v, fromDword(toDword(v), reflect.Int16).(int16))
	v = int16(math.MinInt8)
	assert.Equal(t, v, fromDword(toDword(v), reflect.Int16).(int16))

	v = int32(math.MaxInt32)
	assert.Equal(t, v, fromDword(toDword(v), reflect.Int32).(int32))
	v = int32(math.MinInt32)
	assert.Equal(t, v, fromDword(toDword(v), reflect.Int32).(int32))

	v = uint(math.MaxUint16)
	assert.Equal(t, v, fromDword(toDword(v), reflect.Uint).(uint))

	v = uint8(math.MaxUint8)
	assert.Equal(t, v, fromDword(toDword(v), reflect.Uint8).(uint8))

	v = uint16(math.MaxUint16)
	assert.Equal(t, v, fromDword(toDword(v), reflect.Uint16).(uint16))

	v = uint32(math.MaxUint32)
	assert.Equal(t, v, fromDword(toDword(v), reflect.Uint32).(uint32))

	v = float32(math.MaxFloat32)
	assert.Equal(t, v, fromDword(toDword(v), reflect.Float32).(float32))
	v = float32(math.SmallestNonzeroFloat32)
	assert.Equal(t, v, fromDword(toDword(v), reflect.Float32).(float32))
}

func TestFromQword(t *testing.T) {
	var v interface{}

	v = true
	assert.Equal(t, v, fromQword(toQword(v), reflect.Bool).(bool))
	v = false
	assert.Equal(t, v, fromQword(toQword(v), reflect.Bool).(bool))

	v = int(math.MaxInt16)
	assert.Equal(t, v, fromQword(toQword(v), reflect.Int).(int))
	v = int(math.MinInt16)
	assert.Equal(t, v, fromQword(toQword(v), reflect.Int).(int))

	v = int8(math.MaxInt8)
	assert.Equal(t, v, fromQword(toQword(v), reflect.Int8).(int8))
	v = int8(math.MinInt8)
	assert.Equal(t, v, fromQword(toQword(v), reflect.Int8).(int8))

	v = int16(math.MaxInt8)
	assert.Equal(t, v, fromQword(toQword(v), reflect.Int16).(int16))
	v = int16(math.MinInt8)
	assert.Equal(t, v, fromQword(toQword(v), reflect.Int16).(int16))

	v = int32(math.MaxInt32)
	assert.Equal(t, v, fromQword(toQword(v), reflect.Int32).(int32))
	v = int32(math.MinInt32)
	assert.Equal(t, v, fromQword(toQword(v), reflect.Int32).(int32))

	v = int64(math.MaxInt64)
	assert.Equal(t, v, fromQword(toQword(v), reflect.Int64).(int64))
	v = int64(math.MinInt64)
	assert.Equal(t, v, fromQword(toQword(v), reflect.Int64).(int64))

	v = uint(math.MaxUint16)
	assert.Equal(t, v, fromQword(toQword(v), reflect.Uint).(uint))

	v = uint8(math.MaxUint8)
	assert.Equal(t, v, fromQword(toQword(v), reflect.Uint8).(uint8))

	v = uint16(math.MaxUint16)
	assert.Equal(t, v, fromQword(toQword(v), reflect.Uint16).(uint16))

	v = uint32(math.MaxUint32)
	assert.Equal(t, v, fromQword(toQword(v), reflect.Uint32).(uint32))

	v = uint64(math.MaxUint64)
	assert.Equal(t, v, fromQword(toQword(v), reflect.Uint64).(uint64))

	v = float32(math.MaxFloat32)
	assert.Equal(t, v, fromQword(toQword(v), reflect.Float32).(float32))
	v = float32(math.SmallestNonzeroFloat32)
	assert.Equal(t, v, fromQword(toQword(v), reflect.Float32).(float32))

	v = float64(math.MaxFloat64)
	assert.Equal(t, v, fromQword(toQword(v), reflect.Float64).(float64))
	v = float64(math.SmallestNonzeroFloat64)
	assert.Equal(t, v, fromQword(toQword(v), reflect.Float64).(float64))

	v = complex64(complex(math.MaxFloat32, math.SmallestNonzeroFloat32))
	assert.Equal(t, v, fromQword(toQword(v), reflect.Complex64).(complex64))
	v = complex64(complex(math.SmallestNonzeroFloat32, math.MaxFloat32))
	assert.Equal(t, v, fromQword(toQword(v), reflect.Complex64).(complex64))
}
