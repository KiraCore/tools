package bip39

import "fmt"

type Colors map[int]string

var colors = NewColors()

func NewColors() Colors {
	c := Colors{}
	for i := 0; i < 256; i++ {
		(c)[i] = fmt.Sprintf("\x1b[48;5;%vm", i)
	}
	return c
}
func (c *Colors) GetColor(color int) string {
	return (*c)[color]
}
func (c *Colors) Print(str string, color int) string {
	return fmt.Sprintf("%s%v%s", c.GetColor(color), str, "\x1b[00m")
}
func PrintLine(length int, char string) {
	for i := 0; i < length; i++ {
		fmt.Print(char)
	}
	fmt.Println()

}
