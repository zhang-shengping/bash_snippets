#/bin/bash -x

test="####1-#\#\\#,.jk#"
rep='\#'

# To replace the first occurrence of a pattern with a given string, use
# ${parameter/pattern/string}
echo ${test/#/$rep}

# To replace all occurrences, use ${parameter//pattern/string}
echo ${test//#/$rep}

