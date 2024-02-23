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
of each patch. Call jt6295 sine file.yml to convert the file to a binary ROM file.

To resample output .wav files, use:
	ffmpeg -i patch00.wav -ar 48000 x.wav`,
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
	buf []int		// raw 12-bit data, as integers
	enc []byte		// adpcm-encoded data
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
	if w.Form != "sine" && w.Form != "" {
		fmt.Printf("Waveform '%s' not supported.\n",w.Form)
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

func clip( v *int ) {
	if *v >  2047 { *v =  2047 }
	if *v < -2048 { *v = -2048 }
}

// only works with sine waves for now
func add_wave( buf []int, w WaveDesc ) {
	f0 := 6.283185*float64(w.Freq)/float64(rate)	// 2*pi*f/Fs
	var f float64
	a := float64(w.Amp)
	for k, _ := range buf {
		buf[k] += int(math.Round(a * math.Sin(f)))
		f+=f0
		clip( &buf[k] )
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
	must(enc.Write(&ibuf))
	enc.Close()
}

func dump_patch( fname string, buf []byte ) {
	os.WriteFile(fname, buf, 0666 )
}

func encode( raw []int ) []byte {
	step_size := [49]int{ 16, 17, 19, 21, 23, 25, 28, 31, 34, 37, 41,
		45, 50, 55, 60, 66, 73, 80, 88, 97, 107, 118, 130, 143, 157, 173,
		190, 209, 230, 253, 279, 307, 337, 371, 408, 449, 494, 544, 598, 658,
		724, 796, 876, 963, 1060, 1166, 1282, 1411, 1552 };
	enc := make([]byte,len(raw)/2)
	ss  := 0	// step size
	idx := 0	// step size index for next sample
	last := 0	// last encoded value
	for k, each := range raw {
		ss = step_size[idx]
		code := 0
		diff := each-last
		if diff <0 {
			code |= 8
			diff = -diff
		}
		if diff >= ss {
			code |= 4
			diff -= ss
		}
		if diff >= ss>>1 {
			code |= 2
			diff -= ss>>1
		}
		if diff >= ss>>2 {
			code |= 1
		}
		// calculate the encoded sample value
		diff = ss>>3
		if (code&1)!=0 { diff += ss>>2 }
		if (code&2)!=0 { diff += ss>>1 }
		if (code&4)!=0 { diff += ss    }
		if (code&8)!=0 { diff  = -diff }
		last += diff
		clip( &last )
		// adjust index
		switch( code&7 ) {
			case 4: idx+=2
			case 5: idx+=4
			case 6: idx+=6
			case 7: idx+=8
			default: idx-=1
		}
		if idx<0  { idx=0  }
		if idx>48 { idx=48 }
		// push into the array
		if (k&1)==0 { code <<= 4 } // upper nibble used first
		enc[k>>1] |= byte(code)
		// fmt.Printf("(%02X) %d - %d => %d\n",code,each,last,each-last)
	}
	return enc
}

func Run(cmd *cobra.Command, args []string) {
	var patches []Patch
	read_yaml(args[0], &patches)
	check_patches(patches)
	for k, _ := range patches {
		patches[k].buf = make_patch(patches[k])
		patches[k].enc = encode(patches[k].buf)
		dump_wav( fmt.Sprintf("patch%02d.wav",k), patches[k].buf )
		dump_patch( fmt.Sprintf("patch%02d.bin",k), patches[k].enc )
	}
}