package main

import (
	"fmt"
	"math"
	"reflect"

	"golang.org/x/sys/windows/registry"
)

type SDSettings struct {
	BrowserPath       string `regName:"BrowserPath"       regType:"SZ"`
	UseProfile        bool   `regName:"UseProfile"        regType:"DWORD"`
	EngineURL         string `regName:"EngineURL"         regType:"SZ"`
	ProfileName       string `regName:"ProfileName"       regType:"SZ"`
	InterfaceLanguage string `regName:"InterfaceLanguage" regType:"SZ"`
	SearchCount       uint   `regName:"SearchCount"       regType:"DWORD"`
	DisableNag        bool   `regName:"DisableNag"        regType:"DWORD"`
}

type TestSettings struct {
	BoolValue    bool    `regName:"BoolValue"    regType:"BINARY"`
	IntValue     int     `regName:"IntValue"     regType:"DWORD"`
	Int8Value    int8    `regName:"Int8Value"    regType:"DWORD"`
	Int16Value   int16   `regName:"Int16Value"   regType:"DWORD"`
	Int32Value   int32   `regName:"Int32Value"   regType:"DWORD"`
	Int64Value   int64   `regName:"Int64Value"   regType:"QWORD"`
	UintValue    uint    `regName:"UintValue"    regType:"DWORD"`
	Uint8Value   uint8   `regName:"Uint8Value"   regType:"DWORD"`
	Uint16Value  uint16  `regName:"Uint16Value"  regType:"DWORD"`
	Uint32Value  uint32  `regName:"Uint32Value"  regType:"DWORD"`
	Uint64Value  uint64  `regName:"Uint64Value"  regType:"QWORD"`
	Float32Value float32 `regName:"Float32Value" regType:"DWORD"`
	Float64Value float64 `regName:"Float64Value" regType:"QWORD"`
	StringValue  string  `regName:"StringValue"  regType:"SZ"`
}

func WriteRegistry(kData interface{}, key registry.Key, path string) {
	kdValue := reflect.ValueOf(kData)
	kdType := kdValue.Type()

	rKey, _, err := registry.CreateKey(key, path, registry.WRITE)

	if err == nil {
		defer rKey.Close()
	}

	for i := 0; i < kdType.NumField(); i++ {
		vField := kdValue.Field(i)
		tField := kdType.Field(i)
		fValue := reflect.ValueOf(vField.Interface())

		regName, ok := tField.Tag.Lookup("regName")

		if !ok {
			fmt.Printf("Required 'regName' tag missing for field %q", tField.Name)
			continue
		}

		switch tField.Type.Kind() {
		case reflect.Bool:
			if fValue.Bool() {
				rKey.SetDWordValue(regName, 1)
			} else {
				rKey.SetDWordValue(regName, 0)
			}
		case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32:
			rKey.SetDWordValue(regName, uint32(fValue.Int()))
		case reflect.Int64:
			rKey.SetQWordValue(regName, uint64(fValue.Int()))
		case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32:
			rKey.SetDWordValue(regName, uint32(fValue.Uint()))
		case reflect.Uint64:
			rKey.SetQWordValue(regName, fValue.Uint())
		// case reflect.Uintptr:
		case reflect.Float32:
			rKey.SetDWordValue(regName, uint32(fValue.Float()))
		case reflect.Float64:
			rKey.SetQWordValue(regName, uint64(fValue.Float()))
		// case reflect.Complex64:
		// case reflect.Complex128:
		// case reflect.Array:
		// case reflect.Chan:
		// case reflect.Func:
		// case reflect.Interface:
		// case reflect.Map:
		// case reflect.Ptr:
		// case reflect.Slice:
		case reflect.String:
			rKey.SetStringValue(regName, fValue.String())
		// case reflect.Struct:
		// case reflect.UnsafePointer:
		default:
			panic("Type %q not implemented")
		}
	}
}

func LoadRegistry(kData interface{}, key registry.Key, path string) {
	kdValue := reflect.ValueOf(kData).Elem()
	kdType := kdValue.Type()

	rKey, _, err := registry.CreateKey(key, path, registry.READ)

	if err == nil {
		defer rKey.Close()
	}

	for i := 0; i < kdType.NumField(); i++ {
		vField := kdValue.Field(i)
		tField := kdType.Field(i)

		regName, ok := tField.Tag.Lookup("regName")

		if !ok {
			fmt.Printf("Required 'regName' tag missing for field %q", tField.Name)
			continue
		}

		var value interface{}

		switch _, rType, _ := rKey.GetValue(regName, nil); rType {
		// case registry.NONE:
		case registry.SZ:
			value, _, _ = rKey.GetStringValue(regName)
		// case registry.EXPAND_SZ:
		// case registry.BINARY:
		case registry.DWORD:
			value, _, _ = rKey.GetIntegerValue(regName)
			// value = uint64(value.(uint32))
		// case registry.DWORD_BIG_ENDIAN:
		// case registry.LINK:
		case registry.MULTI_SZ:
			value, _, _ = rKey.GetStringsValue(regName)
		// case registry.RESOURCE_LIST:
		// case registry.FULL_RESOURCE_DESCRIPTOR:
		// case registry.RESOURCE_REQUIREMENTS_LIST:
		case registry.QWORD:
			value, _, _ = rKey.GetIntegerValue(regName)
		default:
			panic("Type %q not implemented")
		}

		switch tField.Type.Kind() {
		case reflect.Bool:
			value = value != 0
		case reflect.Int:
			value = int(value.(uint64))
		case reflect.Int8:
			value = int8(value.(uint64))
		case reflect.Int16:
			value = int16(value.(uint64))
		case reflect.Int32:
			value = int32(value.(uint64))
		case reflect.Int64:
			value = int64(value.(uint64))
		case reflect.Uint:
			value = uint(value.(uint64))
		case reflect.Uint8:
			value = uint8(value.(uint64))
		case reflect.Uint16:
			value = uint16(value.(uint64))
		case reflect.Uint32:
			value = uint32(value.(uint64))
		case reflect.Uint64:
			value = uint64(value.(uint64))
		// case reflect.Uintptr:
		case reflect.Float32:
			value = float32(value.(uint64))
		case reflect.Float64:
			value = float64(value.(uint64))
			// case reflect.Complex64:
			// case reflect.Complex128:
			// case reflect.Array:
			// case reflect.Chan:
			// case reflect.Func:
			// case reflect.Interface:
			// case reflect.Map:
			// case reflect.Ptr:
			// case reflect.Slice:
			// case reflect.String:
			// case reflect.Struct:
			// case reflect.UnsafePointer:
		}

		vField.Set(reflect.ValueOf(value))
	}
}

func main() {
	writeSettings := TestSettings{
		BoolValue:    true,
		IntValue:     int(^uint(0) >> 1),
		Int8Value:    math.MaxInt8,
		Int16Value:   math.MaxInt16,
		Int32Value:   math.MaxInt32,
		Int64Value:   math.MaxInt64,
		UintValue:    ^uint(0),
		Uint8Value:   math.MaxUint8,
		Uint16Value:  math.MaxUint16,
		Uint32Value:  math.MaxInt32,
		Uint64Value:  math.MaxInt64,
		Float32Value: math.MaxFloat32,
		Float64Value: math.MaxFloat64,
		StringValue:  "This is an example string.",
	}

	WriteRegistry(writeSettings, registry.CURRENT_USER, "SOFTWARE\\Clients\\SearchDeflector\\Test")

	fmt.Println(writeSettings)

	readSettings := new(TestSettings)

	LoadRegistry(readSettings, registry.CURRENT_USER, "SOFTWARE\\Clients\\SearchDeflector\\Test")

	fmt.Println(readSettings)
}
