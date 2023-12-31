package dsmr

import (
	"math/big"
	"reflect"
	"testing"

	"github.com/alecthomas/assert/v2"
	"github.com/alecthomas/participle/v2/lexer"
	"github.com/alecthomas/repr"
)

func TestParse(t *testing.T) {
	tests := []struct {
		name     string
		telegram string
		fail     string
		expected *Telegram
	}{
		{
			name: "v2.2",
			telegram: "" +
				"/ISk5\\2MT382-1004\r\n" +
				"\r\n" +
				"0-0:96.1.1(00000000000000)\r\n" +
				"1-0:1.8.1(00001.001*kWh)\r\n" +
				"1-0:1.8.2(00001.001*kWh)\r\n" +
				"1-0:2.8.1(00001.001*kWh)\r\n" +
				"1-0:2.8.2(00001.001*kWh)\r\n" +
				"0-0:96.14.0(0001)\r\n" +
				"1-0:1.7.0(0001.01*kW)\r\n" +
				"1-0:2.7.0(0000.00*kW)\r\n" +
				"0-0:17.0.0(0999.00*kW)\r\n" +
				"0-0:96.3.10(1)\r\n" +
				"0-0:96.13.1()\r\n" +
				"0-0:96.13.0()\r\n" +
				"0-1:24.1.0(3)\r\n" +
				"0-1:96.1.0(000000000000)\r\n" +
				"0-1:24.3.0(161107190000)(00)(60)(1)(0-1:24.2.1)(m3)\r\n" +
				"(00001.001)\r\n" +
				"0-1:24.4.0(1)\r\n" +
				"!\r\n",
			expected: &Telegram{
				Header: header("ISk5\\2MT382-1004"),
				Data: []*Object{
					obj("0-0:96.1.1", str("00000000000000")),
					obj("1-0:1.8.1", mm("00001.001", "kWh")),
					obj("1-0:1.8.2", mm("00001.001", "kWh")),
					obj("1-0:2.8.1", mm("00001.001", "kWh")),
					obj("1-0:2.8.2", mm("00001.001", "kWh")),
					obj("0-0:96.14.0", str("0001")),
					obj("1-0:1.7.0", mm("0001.01", "kW")),
					obj("1-0:2.7.0", mm("0000.00", "kW")),
					obj("0-0:17.0.0", mm("0999.00", "kW")),
					obj("0-0:96.3.10", str("1")),
					obj("0-0:96.13.1", nil),
					obj("0-0:96.13.0", nil),
					obj("0-1:24.1.0", str("3")),
					obj("0-1:96.1.0", str("000000000000")),
					obj("0-1:24.3.0", llc(str("161107190000"), obis("0-1:24.2.1"), lmm("00001.001", "m3"))),
					obj("0-1:24.4.0", str("1")),
				},
				Footer: &Footer{},
			},
		},
		{
			name: "v3.0",
			telegram: "" +
				"/ISk5\\2MT382-1000\r\n" +
				"\r\n" +
				"0-0:96.1.1(4B384547303034303436333935353037)\r\n" +
				"1-0:1.8.1(12345.678*kWh)\r\n" +
				"1-0:1.8.2(12345.678*kWh)\r\n" +
				"1-0:2.8.1(12345.678*kWh)\r\n" +
				"1-0:2.8.2(12345.678*kWh)\r\n" +
				"0-0:96.14.0(0002)\r\n" +
				"1-0:1.7.0(001.19*kW)\r\n" +
				"1-0:2.7.0(000.00*kW)\r\n" +
				"0-0:17.0.0(016*A)\r\n" +
				"0-0:96.3.10(1)\r\n" +
				"0-0:96.13.1(303132333435363738)\r\n" +
				"0-0:96.13.0(303132333435363738393A3B3C3D3E3F303132333435363738393A3B3C3D3E" +
				"3F303132333435363738393A3B3C3D3E3F303132333435363738393A3B3C3D3E3F30313233" +
				"3435363738393A3B3C3D3E3F)\r\n" +
				"0-1:96.1.0(3232323241424344313233343536373839)\r\n" +
				"0-1:24.1.0(03)\r\n" +
				"0-1:24.3.0(090212160000)(00)(60)(1)(0-1:24.2.1)(m3)\r\n" +
				"(00001.001)\r\n" +
				"0-1:24.4.0(1)\r\n" +
				"!\r\n",
			expected: &Telegram{
				Header: header("ISk5\\2MT382-1000"),
				Data: []*Object{
					obj("0-0:96.1.1", str("4B384547303034303436333935353037")),
					obj("1-0:1.8.1", mm("12345.678", "kWh")),
					obj("1-0:1.8.2", mm("12345.678", "kWh")),
					obj("1-0:2.8.1", mm("12345.678", "kWh")),
					obj("1-0:2.8.2", mm("12345.678", "kWh")),
					obj("0-0:96.14.0", str("0002")),
					obj("1-0:1.7.0", mm("001.19", "kW")),
					obj("1-0:2.7.0", mm("000.00", "kW")),
					obj("0-0:17.0.0", mm("016", "A")),
					obj("0-0:96.3.10", str("1")),
					obj("0-0:96.13.1", str("303132333435363738")),
					obj("0-0:96.13.0", str("303132333435363738393A3B3C3D3E3F303132333435363738393A3B3C3D3E3F303132333435363738393A3B3C3D3E3F303132333435363738393A3B3C3D3E3F303132333435363738393A3B3C3D3E3F")),
					obj("0-1:96.1.0", str("3232323241424344313233343536373839")),
					obj("0-1:24.1.0", str("03")),
					obj("0-1:24.3.0", llc(str("090212160000"), obis("0-1:24.2.1"), lmm("00001.001", "m3"))),
					obj("0-1:24.4.0", str("1")),
				},
				Footer: &Footer{},
			},
		},
		{
			name: "v4.2",
			telegram: "" +
				"/KFM5KAIFA-METER\r\n" +
				"\r\n" +
				"1-3:0.2.8(42)\r\n" +
				"0-0:1.0.0(161113205757W)\r\n" +
				"0-0:96.1.1(3960221976967177082151037881335713)\r\n" +
				"1-0:1.8.1(001581.123*kWh)\r\n" +
				"1-0:1.8.2(001435.706*kWh)\r\n" +
				"1-0:2.8.1(000000.000*kWh)\r\n" +
				"1-0:2.8.2(000000.000*kWh)\r\n" +
				"0-0:96.14.0(0002)\r\n" +
				"1-0:1.7.0(02.027*kW)\r\n" +
				"1-0:2.7.0(00.000*kW)\r\n" +
				"0-0:96.7.21(00015)\r\n" +
				"0-0:96.7.9(00007)\r\n" +
				"1-0:99.97.0(3)(0-0:96.7.19)(000104180320W)(0000237126*s)(000101000001W)" +
				"(2147583646*s)(000102000003W)(2317482647*s)\r\n" +
				"1-0:32.32.0(00000)\r\n" +
				"1-0:52.32.0(00000)\r\n" +
				"1-0:72.32.0(00000)\r\n" +
				"1-0:32.36.0(00000)\r\n" +
				"1-0:52.36.0(00000)\r\n" +
				"1-0:72.36.0(00000)\r\n" +
				"0-0:96.13.1()\r\n" +
				"0-0:96.13.0()\r\n" +
				"1-0:31.7.0(000*A)\r\n" +
				"1-0:51.7.0(006*A)\r\n" +
				"1-0:71.7.0(002*A)\r\n" +
				"1-0:21.7.0(00.170*kW)\r\n" +
				"1-0:22.7.0(00.000*kW)\r\n" +
				"1-0:41.7.0(01.247*kW)\r\n" +
				"1-0:42.7.0(00.000*kW)\r\n" +
				"1-0:61.7.0(00.209*kW)\r\n" +
				"1-0:62.7.0(00.000*kW)\r\n" +
				"0-1:24.1.0(003)\r\n" +
				"0-1:96.1.0(4819243993373755377509728609491464)\r\n" +
				"0-1:24.2.1(161129200000W)(00981.443*m3)\r\n" +
				"!6796\r\n",
			expected: &Telegram{
				Header: header("KFM5KAIFA-METER"),
				Data: []*Object{
					obj("1-3:0.2.8", str("42")),
					obj("0-0:1.0.0", ts("161113205757", false)),
					obj("0-0:96.1.1", str("3960221976967177082151037881335713")),
					obj("1-0:1.8.1", mm("001581.123", "kWh")),
					obj("1-0:1.8.2", mm("001435.706", "kWh")),
					obj("1-0:2.8.1", mm("000000.000", "kWh")),
					obj("1-0:2.8.2", mm("000000.000", "kWh")),
					obj("0-0:96.14.0", str("0002")),
					obj("1-0:1.7.0", mm("02.027", "kW")),
					obj("1-0:2.7.0", mm("00.000", "kW")),
					obj("0-0:96.7.21", str("00015")),
					obj("0-0:96.7.9", str("00007")),
					obj("1-0:99.97.0",
						events("3", "0-0:96.7.19",
							event(ts("000104180320", false), "0000237126"),
							event(ts("000101000001", false), "2147583646"),
							event(ts("000102000003", false), "2317482647"),
						),
					),
					obj("1-0:32.32.0", str("00000")),
					obj("1-0:52.32.0", str("00000")),
					obj("1-0:72.32.0", str("00000")),
					obj("1-0:32.36.0", str("00000")),
					obj("1-0:52.36.0", str("00000")),
					obj("1-0:72.36.0", str("00000")),
					obj("0-0:96.13.1", nil),
					obj("0-0:96.13.0", nil),
					obj("1-0:31.7.0", mm("000", "A")),
					obj("1-0:51.7.0", mm("006", "A")),
					obj("1-0:71.7.0", mm("002", "A")),
					obj("1-0:21.7.0", mm("00.170", "kW")),
					obj("1-0:22.7.0", mm("00.000", "kW")),
					obj("1-0:41.7.0", mm("01.247", "kW")),
					obj("1-0:42.7.0", mm("00.000", "kW")),
					obj("1-0:61.7.0", mm("00.209", "kW")),
					obj("1-0:62.7.0", mm("00.000", "kW")),
					obj("0-1:24.1.0", str("003")),
					obj("0-1:96.1.0", str("4819243993373755377509728609491464")),
					obj("0-1:24.2.1", lc(ts("161129200000", false), mm("00981.443", "m3"))),
				},
				Footer: footer("6796"),
			},
		},
		{
			name: "v5.0",
			telegram: "" +
				"/ISk5\\2MT382-1000\r\n" +
				"\r\n" +
				"1-3:0.2.8(50)\r\n" +
				"0-0:1.0.0(161030020000S)\r\n" +
				"0-0:96.1.1(4B384547303034303436333935353037)\r\n" +
				"1-0:1.8.1(000004.426*kWh)\r\n" +
				"1-0:1.8.2(000002.399*kWh)\r\n" +
				"1-0:2.8.1(000002.444*kWh)\r\n" +
				"1-0:2.8.2(000000.000*kWh)\r\n" +
				"0-0:96.14.0(0002)\r\n" +
				"1-0:1.7.0(00.244*kW)\r\n" +
				"1-0:2.7.0(00.000*kW)\r\n" +
				"0-0:96.7.21(00013)\r\n" +
				"0-0:96.7.9(00000)\r\n" +
				"1-0:99.97.0(0)(0-0:96.7.19)\r\n" +
				"1-0:32.32.0(00000)\r\n" +
				"1-0:52.32.0(00000)\r\n" +
				"1-0:72.32.0(00000)\r\n" +
				"1-0:32.36.0(00000)\r\n" +
				"1-0:52.36.0(00000)\r\n" +
				"1-0:72.36.0(00000)\r\n" +
				"0-0:96.13.0()\r\n" +
				"1-0:32.7.0(0230.0*V)\r\n" +
				"1-0:52.7.0(0230.0*V)\r\n" +
				"1-0:72.7.0(0229.0*V)\r\n" +
				"1-0:31.7.0(0.48*A)\r\n" +
				"1-0:51.7.0(0.44*A)\r\n" +
				"1-0:71.7.0(0.86*A)\r\n" +
				"1-0:21.7.0(00.070*kW)\r\n" +
				"1-0:41.7.0(00.032*kW)\r\n" +
				"1-0:61.7.0(00.142*kW)\r\n" +
				"1-0:22.7.0(00.000*kW)\r\n" +
				"1-0:42.7.0(00.000*kW)\r\n" +
				"1-0:62.7.0(00.000*kW)\r\n" +
				"0-1:24.1.0(003)\r\n" +
				"0-1:96.1.0(3232323241424344313233343536373839)\r\n" +
				"0-1:24.2.1(161030020000S)(00000.107*m3)\r\n" +
				"0-2:24.1.0(003)\r\n" +
				"0-2:96.1.0()\r\n" +
				"!8397\r\n",
			expected: &Telegram{
				Header: header("ISk5\\2MT382-1000"),
				Data: []*Object{
					obj("1-3:0.2.8", str("50")),
					obj("0-0:1.0.0", ts("161030020000", true)),
					obj("0-0:96.1.1", str("4B384547303034303436333935353037")),
					obj("1-0:1.8.1", mm("000004.426", "kWh")),
					obj("1-0:1.8.2", mm("000002.399", "kWh")),
					obj("1-0:2.8.1", mm("000002.444", "kWh")),
					obj("1-0:2.8.2", mm("000000.000", "kWh")),
					obj("0-0:96.14.0", str("0002")),
					obj("1-0:1.7.0", mm("00.244", "kW")),
					obj("1-0:2.7.0", mm("00.000", "kW")),
					obj("0-0:96.7.21", str("00013")),
					obj("0-0:96.7.9", str("00000")),
					obj("1-0:99.97.0", events("0", "0-0:96.7.19")),
					obj("1-0:32.32.0", str("00000")),
					obj("1-0:52.32.0", str("00000")),
					obj("1-0:72.32.0", str("00000")),
					obj("1-0:32.36.0", str("00000")),
					obj("1-0:52.36.0", str("00000")),
					obj("1-0:72.36.0", str("00000")),
					obj("0-0:96.13.0", nil),
					obj("1-0:32.7.0", mm("0230.0", "V")),
					obj("1-0:52.7.0", mm("0230.0", "V")),
					obj("1-0:72.7.0", mm("0229.0", "V")),
					obj("1-0:31.7.0", mm("0.48", "A")),
					obj("1-0:51.7.0", mm("0.44", "A")),
					obj("1-0:71.7.0", mm("0.86", "A")),
					obj("1-0:21.7.0", mm("00.070", "kW")),
					obj("1-0:41.7.0", mm("00.032", "kW")),
					obj("1-0:61.7.0", mm("00.142", "kW")),
					obj("1-0:22.7.0", mm("00.000", "kW")),
					obj("1-0:42.7.0", mm("00.000", "kW")),
					obj("1-0:62.7.0", mm("00.000", "kW")),
					obj("0-1:24.1.0", str("003")),
					obj("0-1:96.1.0", str("3232323241424344313233343536373839")),
					obj("0-1:24.2.1", lc(ts("161030020000", true), mm("00000.107", "m3"))),
					obj("0-2:24.1.0", str("003")),
					obj("0-2:96.1.0", nil),
				},
				Footer: footer("8397"),
			},
		},
		{
			name:     "InvalidTelegram",
			telegram: "invalid_telegram",
			fail:     "1:1: unexpected token \"invalid\"",
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			telegram, err := Parse(test.telegram)
			if test.fail != "" {
				assert.EqualError(t, err, test.fail)
			} else {
				normalizeTelegram(telegram)

				assert.NoError(t, err)
				assert.Equal(t,
					repr.String(test.expected, repr.Indent("  ")),
					repr.String(telegram, repr.Indent("  ")))
			}
		})
	}
}

func normalizeTelegram(t *Telegram) *Telegram {
	if t == nil {
		return nil
	}
	t.Pos = lexer.Position{}
	normalizeNodes(t.children())

	return t
}

func normalizeNodes(nodes []Node) {
	for _, node := range nodes {
		rv := reflect.ValueOf(node)
		if node == nil || rv.IsNil() {
			return
		}

		rv = reflect.Indirect(rv)
		rv.FieldByName("Pos").Set(reflect.ValueOf(lexer.Position{}))

		normalizeNodes(node.children())
	}
}

func header(v string) *Header {
	return &Header{Value: v}
}

func footer(v string) *Footer {
	return &Footer{Value: v}
}

func obj(o string, v Value) *Object {
	return &Object{OBIS: obis(o), Value: v}
}

func events(c string, o string, v ...*Event) *EventLog {
	return &EventLog{Count: num(c), OBIS: obis(o), Value: v}
}

func event(ts *Timestamp, v string) *Event {
	return &Event{Timestamp: ts, Value: mm(v, "s")}
}

func lc(ts *Timestamp, v *Measurement) *LastCapture {
	return &LastCapture{Timestamp: ts, Value: v}
}

func llc(ts *String, o *OBIS, v *LegacyMeasurement) *LegacyLastCapture {
	return &LegacyLastCapture{Timestamp: ts, OBIS: o, Value: v}
}

func obis(v string) *OBIS {
	return &OBIS{Value: v}
}

func mm(v string, u string) *Measurement {
	return &Measurement{Value: num(v), Unit: str(u)}
}

func lmm(v string, u string) *LegacyMeasurement {
	return &LegacyMeasurement{Value: num(v), Unit: str(u)}
}

func ts(v string, dst bool) *Timestamp {
	return &Timestamp{Value: v, DST: dst}
}

func num(v string) *Number {
	b := &big.Float{}
	_, _, _ = b.Parse(v, 0)

	return &Number{Value: b}
}

func str(v string) *String {
	return &String{Value: v}
}
