package main

import (
	"log"
	"reflect"

	"golang.org/x/sys/windows/registry"
)

type SDSettings struct {
	BrowserPath       string `regName:"BrowserPath"`
	UseProfile        bool   `regName:"UseProfile"`
	EngineURL         string `regName:"EngineURL"`
	ProfileName       string `regName:"ProfileName"`
	InterfaceLanguage string `regName:"InterfaceLanguage"`
	SearchCount       uint   `regName:"SearchCount"`
	DisableNag        bool   `regName:"DisableNag"`
}

func WriteRegistry(kData interface{}, key registry.Key, path string) {
	kdValue := reflect.ValueOf(kData).Elem()
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
			log.Printf("Required 'regName' tag missing for field %q", tField.Name)
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

func LoadRegistry(kData interface{}, k registry.Key, path string) {
	kdValue := reflect.ValueOf(kData).Elem()
	kdType := kdValue.Type()

	rKey, err := registry.OpenKey(k, path, registry.READ)

	if err == nil {
		defer rKey.Close()
	} else {
		log.Panicf("Could not open key %#v with path %q", k, path)
	}

	for i := 0; i < kdType.NumField(); i++ {
		field := kdType.Field(i)
		log.Println(field)

		regName, ok := field.Tag.Lookup("regName")

		if !ok {
			log.Printf("Required 'regName' tag missing for field %q", field.Name)
			continue
		}

		_, valType, err := rKey.GetValue(regName, nil)

		if err != nil {
			log.Panicln("Error getting value for %q with 'regName' %q", field.Name, regName)
		}

		switch valType {
		case registry.NONE:
			log.Panicln("Registry type is NONE")
		case registry.SZ:
			value, _, _ := rKey.GetStringValue(regName)
			kdValue.FieldByName(field.Name).SetString(value)
		case registry.EXPAND_SZ:
			// todo
		case registry.BINARY:
		case registry.DWORD:
			value, _, _ := rKey.GetIntegerValue(regName)
			kdValue.FieldByName(field.Name).SetInt(int64(value))
		case registry.DWORD_BIG_ENDIAN:
		case registry.LINK:
		case registry.MULTI_SZ:
		case registry.RESOURCE_LIST:
		case registry.FULL_RESOURCE_DESCRIPTOR:
		case registry.RESOURCE_REQUIREMENTS_LIST:
		case registry.QWORD:
		}
	}
}

func main() {
	settings := new(SDSettings)

	WriteRegistry(settings, registry.CURRENT_USER, "SOFTWARE\\Clients\\SearchDeflector")

	log.Println(settings)
}
