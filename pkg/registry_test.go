package registry

import (
	"fmt"
	"math"
	"math/bits"
	"reflect"
	"testing"
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

func TestFromBytes(t *testing.T) {
	d := ExampleData{
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

	okMsg := "Check 'fromBytes(toBytes(v), %#q) == v' OK"
	failMsg := "Check 'fromBytes(toBytes(v), %#q) == v' FAILED"

	if fromBytes(toBytes(d.BoolValue), reflect.Bool).(bool) == d.BoolValue {
		t.Log(fmt.Sprintf(okMsg, reflect.Bool))
	} else {
		t.Log(fmt.Sprintf(failMsg, reflect.Bool))
		t.Fail()
	}

	if fromBytes(toBytes(d.IntValue), reflect.Int).(int) == d.IntValue {
		t.Log(fmt.Sprintf(okMsg, reflect.Int))
	} else {
		t.Log(fmt.Sprintf(failMsg, reflect.Int))
		t.Fail()
	}

	if fromBytes(toBytes(d.Int8Value), reflect.Int8).(int8) == d.Int8Value {
		t.Log(fmt.Sprintf(okMsg, reflect.Int8))
	} else {
		t.Log(fmt.Sprintf(failMsg, reflect.Int8))
		t.Fail()
	}

	if fromBytes(toBytes(d.Int16Value), reflect.Int16).(int16) == d.Int16Value {
		t.Log(fmt.Sprintf(okMsg, reflect.Int16))
	} else {
		t.Log(fmt.Sprintf(failMsg, reflect.Int16))
		t.Fail()
	}

	if fromBytes(toBytes(d.Int32Value), reflect.Int32).(int32) == d.Int32Value {
		t.Log(fmt.Sprintf(okMsg, reflect.Int32))
	} else {
		t.Log(fmt.Sprintf(failMsg, reflect.Int32))
		t.Fail()
	}

	if fromBytes(toBytes(d.Int64Value), reflect.Int64).(int64) == d.Int64Value {
		t.Log(fmt.Sprintf(okMsg, reflect.Int64))
	} else {
		t.Log(fmt.Sprintf(failMsg, reflect.Int64))
		t.Fail()
	}

	if fromBytes(toBytes(d.IntValue), reflect.Uint).(uint) == d.UintValue {
		t.Log(fmt.Sprintf(okMsg, reflect.Uint))
	} else {
		t.Log(fmt.Sprintf(failMsg, reflect.Uint))
		t.Fail()
	}

	if fromBytes(toBytes(d.IntValue), reflect.Uint8).(uint8) == d.Uint8Value {
		t.Log(fmt.Sprintf(okMsg, reflect.Uint8))
	} else {
		t.Log(fmt.Sprintf(failMsg, reflect.Uint8))
		t.Fail()
	}

	if fromBytes(toBytes(d.Int16Value), reflect.Uint16).(uint16) == d.Uint16Value {
		t.Log(fmt.Sprintf(okMsg, reflect.Uint16))
	} else {
		t.Log(fmt.Sprintf(failMsg, reflect.Uint16))
		t.Fail()
	}

	if fromBytes(toBytes(d.Int32Value), reflect.Uint32).(uint32) == d.Uint32Value {
		t.Log(fmt.Sprintf(okMsg, reflect.Uint32))
	} else {
		t.Log(fmt.Sprintf(failMsg, reflect.Uint32))
		t.Fail()
	}

	if fromBytes(toBytes(d.Int64Value), reflect.Uint64).(uint64) == d.Uint64Value {
		t.Log(fmt.Sprintf(okMsg, reflect.Uint64))
	} else {
		t.Log(fmt.Sprintf(failMsg, reflect.Uint64))
		t.Fail()
	}

	if fromBytes(toBytes(d.Float32Value), reflect.Float32).(float32) == d.Float32Value {
		t.Log(fmt.Sprintf(okMsg, reflect.Float32))
	} else {
		t.Log(fmt.Sprintf(failMsg, reflect.Float32))
		t.Fail()
	}

	if fromBytes(toBytes(d.Float64Value), reflect.Float64).(float64) == d.Float64Value {
		t.Log(fmt.Sprintf(okMsg, reflect.Float64))
	} else {
		t.Log(fmt.Sprintf(failMsg, reflect.Float64))
		t.Fail()
	}

	if fromBytes(toBytes(d.Complex64Value), reflect.Complex64).(complex64) == d.Complex64Value {
		t.Log(fmt.Sprintf(okMsg, reflect.Complex64))
	} else {
		t.Log(fmt.Sprintf(failMsg, reflect.Complex64))
		t.Fail()
	}

	if fromBytes(toBytes(d.Complex128Value), reflect.Complex128).(complex128) == d.Complex128Value {
		t.Log(fmt.Sprintf(okMsg, reflect.Complex128))
	} else {
		t.Log(fmt.Sprintf(failMsg, reflect.Complex128))
		t.Fail()
	}

	if fromBytes(toBytes(d.StringValue), reflect.String).(string) == d.StringValue {
		t.Log(fmt.Sprintf(okMsg, reflect.String))
	} else {
		t.Log(fmt.Sprintf(failMsg, reflect.String))
		t.Fail()
	}
}
