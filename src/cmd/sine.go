package cmd

import (
	"fmt"
	"math"
	"os"

	"github.com/go-audio/audio"
	"github.com/go-audio/wav"
	"github.com/spf13/cobra"
	"gopkg.in/yaml.v2"
)

var rate int

// sineCmd represents the sine command
var sineCmd = &cobra.Command{
	Use:   "sine <cfg.yml>",
	Short: "Generates a compatible ROM file with sine waves from a YAML file",
	Long: `Create a YAML file with entries for each sound patch, listing the contents
of each patch. Call jt6295 sine file.yml to convert the file to a binary ROM file`,
	Args: cobra.ExactArgs(1),
	Run: Run,
}

type WaveDesc struct {
	Form string `yaml:"form"`	// sine, square
	Amp  int	`yaml:"amp"` 	// 12-bit signed amplitude
	Freq int	`yaml:"freq"`	// frequency, up to 4kHz
}

type Patch struct{
	Dur float64	`yaml:"duration"` // duration in seconds of the patch
	Waves []WaveDesc `yaml:"waves"`
	// filled by Go
	buf []int
}

func init() {
	rootCmd.AddCommand(sineCmd)
	sineCmd.Flags().IntVarP( &rate, "rate", "r", 8000, "Sampling rate (Hz)")
}

func must( e error ) {
	if e != nil {
		fmt.Println(e)
		os.Exit(1)
	}
}

func read_yaml( fname string, datain interface{} ) {
	buf, e := os.ReadFile(fname)
	must(e)
	must(yaml.Unmarshal(buf, datain))
}

func check_patches( p []Patch ) {
	if len(p)==0 {
		fmt.Println("Specify one or more patches to convert in the YAML file.\nNothing done.")
		os.Exit(0)
	}
	if len(p)>64 {
		fmt.Println("You cannot specify more than 64 patches.\nNothing done.")
		os.Exit(0)
	}
}

func check_wave( w WaveDesc ) {
	if w.Form != "sine" || w.Form != "" {
		fmt.Printf("Waveform %s not supported.",w.Form)
		os.Exit(1)
	}
	if w.Amp>2047 || w.Amp<0 {
		fmt.Println("Waveform amplitude must be in the 0-2047 range")
		os.Exit(1)
	}
	if w.Freq > rate/2 {
		fmt.Println("Waveform frequency cannot be larger than half the sampling rate")
		os.Exit(1)
	}
}

// only works with sine waves for now
func add_wave( buf []int, w WaveDesc ) {
	f0 := 6.283185*float64(w.Freq)/float64(rate)	// 2*pi*f/Fs
	var f float64
	a := float64(w.Amp)
	for k, _ := range buf {
		buf[k] += int(math.Round(a * math.Sin(f)))
		f+=f0
		if buf[k]>2047 {
			buf[k]=2047
		}
		if buf[k]<(-2048) {
			buf[k]=-2048
		}
	}
}

func make_patch( p Patch ) []int {
	N := int(math.Round(p.Dur*float64(rate)))	// number of samples
	buf := make([]int,N)
	for k, _ := range p.Waves {
		check_wave( p.Waves[k] )
		add_wave( buf, p.Waves[k] )
	}
	return buf
}

func dump_wav( fname string, buf []int ) {
	f,e  := os.Create(fname)
	must(e)
	defer f.Close()
	enc := wav.NewEncoder(f,rate,16,1,1)
	ibuf := audio.IntBuffer{
		Data: buf,
		SourceBitDepth: 16,
		Format: &audio.Format{
			NumChannels: 1,
			SampleRate: rate,
		},
	}
	enc.Write(&ibuf)
	enc.Close()
}

func Run(cmd *cobra.Command, args []string) {
	var patches []Patch
	read_yaml(args[0], &patches)
	check_patches(patches)
	for k, _ := range patches {
		patches[k].buf = make_patch(patches[k])
		dump_wav( fmt.Sprintf("path%d.wav",k), patches[k].buf )
	}
}