/*
Copyright © 2024 NAME HERE <EMAIL ADDRESS>

*/
package cmd

import (
	"os"
	"strings"

	"github.com/spf13/cobra"
)

// wavCmd represents the wav command
var wavCmd = &cobra.Command{
	Use:   "wav patch.bin",
	Short: "converts a patch to wav",
	// Long: ,
	Run: runWav,
	Args: cobra.ExactArgs(1),
}

func init() {
	rootCmd.AddCommand(wavCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// wavCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// wavCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}

func decode( enc []byte ) (dec []int) {
	dec = make([]int,len(enc)*2)
	idx := 0	// step size index for next sample
	last := 0	// last encoded value
	for k, _ := range dec {
		code := enc[k>>1]
		if (k&1)==0 { code >>=4 }
		dec[k] = last + decOne(int(code), &idx)
		clip( &dec[k] )
		last = dec[k]
	}
	return dec
}

func runWav(cmd *cobra.Command, args []string) {
	fname := args[0]
	buf, e := os.ReadFile(fname)
	must(e)
	dec := decode(buf)
	fname = strings.TrimSuffix(fname,".bin")+".wav"
	dump_wav(fname, dec)
}