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
	assert.Equal(t, d.BoolValue, fromBytes(toBytes(d.BoolValue), reflect.Bool).(bool))

	assert.Equal(t, d.IntValue, fromBytes(toBytes(d.IntValue), reflect.Int).(int))
	assert.Equal(t, d.Int8Value, fromBytes(toBytes(d.Int8Value), reflect.Int8).(int8))
	assert.Equal(t, d.Int16Value, fromBytes(toBytes(d.Int16Value), reflect.Int16).(int16))
	assert.Equal(t, d.Int16Value, fromBytes(toBytes(d.Int16Value), reflect.Int16).(int16))
	assert.Equal(t, d.Int32Value, fromBytes(toBytes(d.Int32Value), reflect.Int32).(int32))
	assert.Equal(t, d.Int64Value, fromBytes(toBytes(d.Int64Value), reflect.Int64).(int64))

	assert.Equal(t, d.UintValue, fromBytes(toBytes(d.UintValue), reflect.Uint).(uint))
	assert.Equal(t, d.Uint8Value, fromBytes(toBytes(d.Uint8Value), reflect.Uint8).(uint8))
	assert.Equal(t, d.Uint16Value, fromBytes(toBytes(d.Uint16Value), reflect.Uint16).(uint16))
	assert.Equal(t, d.Uint16Value, fromBytes(toBytes(d.Uint16Value), reflect.Uint16).(uint16))
	assert.Equal(t, d.Uint32Value, fromBytes(toBytes(d.Uint32Value), reflect.Uint32).(uint32))
	assert.Equal(t, d.Uint64Value, fromBytes(toBytes(d.Uint64Value), reflect.Uint64).(uint64))

	assert.Equal(t, d.Float32Value, fromBytes(toBytes(d.Float32Value), reflect.Float32).(float32))
	assert.Equal(t, d.Float64Value, fromBytes(toBytes(d.Float64Value), reflect.Float64).(float64))

	assert.Equal(t, d.Complex64Value, fromBytes(toBytes(d.Complex64Value), reflect.Complex64).(complex64))
	assert.Equal(t, d.Complex128Value, fromBytes(toBytes(d.Complex128Value), reflect.Complex128).(complex128))

	assert.Equal(t, d.StringValue, fromBytes(toBytes(d.StringValue), reflect.String).(string))
}

func TestFromDword(t *testing.T) {
	assert.Equal(t, d.BoolValue, fromDword(toDword(d.BoolValue), reflect.Bool).(bool))

	assert.Equal(t, d.IntValue, fromDword(toDword(d.IntValue), reflect.Int).(int))
	assert.Equal(t, d.Int8Value, fromDword(toDword(d.Int8Value), reflect.Int8).(int8))
	assert.Equal(t, d.Int16Value, fromDword(toDword(d.Int16Value), reflect.Int16).(int16))
	assert.Equal(t, d.Int32Value, fromDword(toDword(d.Int32Value), reflect.Int32).(int32))

	assert.Equal(t, d.UintValue, fromDword(toDword(d.UintValue), reflect.Uint).(uint))
	assert.Equal(t, d.Uint8Value, fromDword(toDword(d.Uint8Value), reflect.Uint8).(uint8))
	assert.Equal(t, d.Uint16Value, fromDword(toDword(d.Uint16Value), reflect.Uint16).(uint16))
	assert.Equal(t, d.Uint32Value, fromDword(toDword(d.Uint32Value), reflect.Uint32).(uint32))

	assert.Equal(t, d.Float32Value, fromDword(toDword(d.Float32Value), reflect.Float32).(float32))
}

func TestFromQword(t *testing.T) {
	assert.Equal(t, d.BoolValue, fromQword(toQword(d.BoolValue), reflect.Bool).(bool))

	assert.Equal(t, d.IntValue, fromQword(toQword(d.IntValue), reflect.Int).(int))
	assert.Equal(t, d.Int8Value, fromQword(toQword(d.Int8Value), reflect.Int8).(int8))
	assert.Equal(t, d.Int16Value, fromQword(toQword(d.Int16Value), reflect.Int16).(int16))
	assert.Equal(t, d.Int32Value, fromQword(toQword(d.Int32Value), reflect.Int32).(int32))
	assert.Equal(t, d.Int64Value, fromQword(toQword(d.Int64Value), reflect.Int64).(int64))

	assert.Equal(t, d.UintValue, fromQword(toQword(d.UintValue), reflect.Uint).(uint))
	assert.Equal(t, d.Uint8Value, fromQword(toQword(d.Uint8Value), reflect.Uint8).(uint8))
	assert.Equal(t, d.Uint16Value, fromQword(toQword(d.Uint16Value), reflect.Uint16).(uint16))
	assert.Equal(t, d.Uint32Value, fromQword(toQword(d.Uint32Value), reflect.Uint32).(uint32))
	assert.Equal(t, d.Uint64Value, fromQword(toQword(d.Uint64Value), reflect.Uint64).(uint64))

	assert.Equal(t, d.Float32Value, fromQword(toQword(d.Float32Value), reflect.Float32).(float32))
	assert.Equal(t, d.Float64Value, fromQword(toQword(d.Float64Value), reflect.Float64).(float64))

	assert.Equal(t, d.Complex64Value, fromQword(toQword(d.Complex64Value), reflect.Complex64).(complex64))
}
