#!/usr/bin/ruby
require 'rubygems'
require 'ruby-progressbar'
require 'optparse'
require 'pp'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: load-images.rb [options]"

  opts.on('-D', '--dir PATH', 'Path to directory containing tarballs.') { |v| options[:dir] = v }
  opts.on('-r', '--registry DOCKERREF', 'Name of docker registry to push.') { |v| options[:registry] = v }
  opts.on('-d', '--dryrun', 'Just output commands, don\'t run.') { options[:dryrun] = true }
  opts.on('-v', '--verbose', 'Verbose output') { options[:verbose] = true }
  opts.on('-h', '--help', 'Prints this help.') { puts opts; exit }

end.parse!


options[:dir] != NIL ? directory = options[:dir] : directory="./"
options[:registry] != NIL ? registry = options[:registry] : registry="localhost:5000"

tarballs = Dir.entries("#{directory}").select { |f| f =~ /\.tar\.gz$/ }

bar = ProgressBar.create(:format => '%t |%b>>%i| [%c/%C]', :title=> "Loading", :total => tarballs.size)

tarballs.each do | tarball |

  regex = directory.clone
  regex[0]='' if  regex[0]=='/' 

  cmd_untar = "tar -C #{directory} -xf #{directory}#{tarball} --transform 's%#{regex}\\w*%TMP%'"
  options[:dryrun] ? printf("  SYSTEM: %s\n",cmd_untar) : system(cmd_untar);
  
  sub_tarballs = Dir.entries("#{directory}TMP/")
  sub_tarballs.shift
  sub_tarballs.shift
  bar2 = ProgressBar.create(:format => '%t |%b>>%i| [%c/%C]', :title=> "Extracting", :total => sub_tarballs.size)

  sub_tarballs.each do  | sub_tarball |

    is = sub_tarball.sub('_','/')
    is = is.sub('.tar','')

    cmd_load = "skopeo --tls-verify=false copy docker-archive:#{directory}/TMP/#{sub_tarball} docker://#{registry}/#{is}"
    options[:dryrun] ? printf("  SYSTEM: %s\n",cmd_load) : system(cmd_load);

    bar2.increment


  end
  cmd_clean = "rm -rf #{directory}/TMP/"
#options[:dryrun] ? printf("  SYSTEM: %s\n",cmd_clean) : system(cmd_clean);
  bar.increment


end


bar.title="All finished."

