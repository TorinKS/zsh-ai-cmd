# Could AI in the Terminal Make Us Worse Engineers?

Imagine this: a DevOps engineer with 10 years of experience builds a small script that translates natural language into shell commands. A month later, he can't write `tar -xzf` from memory. A command he's typed thousands of times. His brain, given the option, quietly stopped retaining what the tool could retrieve in under a second. Is this our future reality?

I wanted to check whether AI in the terminal would negatively impact me, so I built a zsh plugin called [zsh-ai-cmd](https://github.com/TorinKS/zsh-ai-cmd) to test it firsthand. A month of daily use gave me an answer — just not the simple one I was hoping for.

## The Convenience Trap

The workflow is seductive. You type:

```
# find all files larger than 100MB in home directory
```

Press Enter. The plugin intercepts the line, gathers your environment context — OS, working directory, available tools, git status, recent commands — ships it to an AI model, and replaces your input with:

```
find ~ -type f -size +100M -exec ls -lh {} \;
```

Highlighted in green. Press Enter again to execute, Ctrl+C to cancel.

The key design decision in [_ai-cmd-accept-line](https://github.com/TorinKS/zsh-ai-cmd/blob/main/functions/_ai-cmd-accept-line) is that it never auto-executes:

```zsh
# Do NOT call .accept-line — let the user review and press Enter again
return 0
```

You always see the command before it runs. This pattern could save from dangerous outputs — an `rm -rf /tmp/*` that would have nuked active Unix sockets, a `chmod -R 777 .` that would have broken SSH keys.

But "you see the command" isn't the same as "you understand the command." And that's where the degradation begins.

## What Does Understanding Mean?

Test yourself after a month of using AI for commands. Simple commands (ls, cd, grep) — no change. Complex commands requiring real thought — no change either. The erosion should happen in the middle: commands you used to know but now don't bother remembering. `tar -xzf`. `awk '{print $3}'`. `find -mtime`. The brain, being efficient, decides: why store what you can retrieve in a second?

This mirrors a well-documented phenomenon in psychology called the Google Effect (Sparrow et al., 2011): people are less likely to remember information when they know they can look it up. The terminal AI is the Google Effect, accelerated. Google requires you to formulate a search query, scan results, adapt the answer. The AI plugin takes a thought and returns a command. The cognitive gap between "I want to do X" and "here's the exact command" shrinks to a single Enter press.

## The Safety Paradox

The plugin includes a [safety check](https://github.com/TorinKS/zsh-ai-cmd/blob/main/functions/_ai-cmd-safety) that scans generated commands against 23 dangerous patterns — `rm -rf /`, fork bombs, disk wipes, `curl | sh`, and others:

```zsh
dangerous_patterns=(
    '*rm -rf /*'
    '*dd if=* of=/dev/*'
    '*curl *\|*sh*'
    '*shutdown*'
    ...
)
```

Dangerous commands get highlighted in red with a warning. Safe ones glow green with "[ok]." This is responsible design. But it introduces a subtle problem: the green highlight creates trust. After seeing "[ok]" a hundred times, you stop reading the command. You just press Enter.

The real near-disasters involve commands that are syntactically valid but semantically wrong. `find /var/log -mtime +7 -delete` is missing `-type f` — it deletes directories too. No pattern list will catch that. No safety check will flag "technically correct but subtly dangerous."

The safety check catches catastrophic failures. It doesn't catch the slow, quiet kind — the commands that do 90% of what you wanted and damage the other 10%.

## The Autonomy Question

Picture this: you're on a remote server. No plugin. No internet. You need to extract an archive. And you spend 15 seconds trying to recall `tar` syntax — a command you've used thousands of times — feeling genuine uncertainty.

This is the real question. Not "does AI make you faster?" (it does) or "does AI make you more productive?" (probably) but: **what happens when the AI isn't there?**

Your laptop dies. The API is down. You're on an air-gapped server in a datacenter. Your internet goes out. These aren't hypotheticals — they're Tuesdays.

A tool that makes you faster when available but less capable when unavailable has a net effect that depends entirely on reliability. And the reliability of external API calls from a shell plugin, through the internet, to a cloud service, is definitionally less than the reliability of knowledge in your own head.

## The Historical Pattern

We've been here before. Every generation of tooling has triggered the same debate:

- Did IDEs make programmers forget language syntax? (Partially, yes.)
- Did Stack Overflow make developers forget algorithms? (Partially, yes.)
- Did GPS make people forget navigation? (Research says yes — Dahmani & Bherer, 2020.)
- Did calculators make students worse at arithmetic? (Yes, but we decided we don't care.)

The calculator parallel is telling. We decided, as a society, that the tradeoff was worth it. Mental arithmetic skills declined, but the ability to solve higher-order problems improved because we weren't wasting cognitive load on multiplication.

Is `tar -xzf` the multiplication of system administration? Is it something we should feel fine outsourcing to a machine so we can think about architecture, reliability, and design instead?

Maybe. But there's a difference between a calculator and an AI command generator. The calculator gives you the exact, deterministic answer every time. The AI gives you a probable answer that's usually right. When your calculator says 847, it's 847. When your AI says `find /var/log -mtime +7 -delete`, it might be silently missing `-type f`.

## The Counterargument: Some Commands Shouldn't Live in Your Head

There is, however, a class of commands where the degradation argument falls apart entirely. Consider this:

```
# list all pods with their sidecar container names
```

The AI returns:

```
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{range .spec.containers[*]}{.name}{"\t"}{end}{"\n"}{end}' | grep -i sidecar
```

Nobody has this memorized. Nobody should. This is not `tar -xzf` — a stable command with stable flags that you could reasonably internalize. This is a nested jsonpath expression with range iterators, tab-separated output formatting, and a pipeline filter. The syntax is hostile to human memory by design.

Or try this one from memory:

```
kubectl get pods --all-namespaces -o json | jq -r '.items[] | select(.status.containerStatuses[]?.state.waiting.reason == "CrashLoopBackOff") | .metadata.namespace + "/" + .metadata.name'
```

That finds all pods in CrashLoopBackOff across every namespace. It pipes kubectl JSON output through jq with array iteration, nested field access, null-safe operators, string concatenation. Writing this from scratch takes even experienced Kubernetes engineers a few minutes of trial and error, checking the API schema, getting the jq syntax right.

With the AI plugin, you type:

```
# find all crashing pods across all namespaces
```

And you get a working command in under a second.

The degradation thesis applies to commands in a specific band: things you once knew and stopped retaining. Commands like the kubectl examples above were never in that band. They live in a different category — commands you construct from documentation every time, commands where the cognitive effort isn't "remembering" but "composing." Outsourcing composition to AI doesn't erode memory because there was no memory to erode. It replaces a 10-minute Stack Overflow session with a 1-second generation.

The same applies across modern infrastructure tooling:

```
# show me the top 10 memory-consuming pods sorted by usage
kubectl top pods --all-namespaces --sort-by=memory | head -20

# get all ingress rules with their backends across namespaces
kubectl get ingress --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{range .spec.rules[*]}{.host}{"\t"}{range .http.paths[*]}{.path}{" -> "}{.backend.service.name}:{.backend.service.port.number}{"\n"}{end}{end}{end}'
```

That last one is 270 characters of nested jsonpath. The "just learn it properly" argument doesn't apply here — this isn't knowledge, it's syntax assembly. The engineer who understands Kubernetes networking, ingress routing, and service backends is not a worse engineer for letting AI assemble the jsonpath. They're a faster one.

This is the strongest counterargument to the degradation thesis: **not all commands are equal.** Forgetting `tar -xzf` is a loss. Never memorizing kubectl jsonpath syntax is just common sense.

## The Middle Path

There are no definitive answers yet, but here's a framework worth considering.

**Use AI for recall, not for understanding.** If you've written `tar -xzf` a hundred times and just can't remember the flags today, let the AI fill in the gap. But if you're using `find` with `-exec` for the first time, read the command the AI gives you. Understand every flag. Look up what you don't recognize.

**Treat the green highlight as a starting point, not a verdict.** The safety check catches `rm -rf /`. It doesn't catch `rm -rf ./build` when you meant `rm -rf ./build/cache`. Read before you execute.

**Keep your offline skills alive.** Occasionally, deliberately, type the command yourself. Use the AI as a check, not a crutch. Like physical exercise — you don't stop walking just because cars exist.

**Be honest about what you're trading.** You gain speed, you lose retention. Whether that trade is worth it depends on how often you're on a server without internet access — and how comfortable you are with the answer.

## The Uncomfortable Truth

The honest answer is that we don't know yet. AI in the command line is too new for longitudinal studies. One-month experiments are data points, not conclusions.

What we do know is that AI tool work. They save time. The reduce context-switching.  And they slowly, quietly, makes you less capable of doing the thing they do for you.

Whether that matters is a question each engineer has to answer for themselves. The plugin will keep working either way.

---

*[zsh-ai-cmd](https://github.com/TorinKS/zsh-ai-cmd) is a zsh plugin that translates natural language into shell commands using AI (Anthropic Claude, OpenAI, or local Ollama). No Python, no Node — just zsh, curl, and jq.*

