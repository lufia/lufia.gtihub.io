import type { promises, Stats } from "fs";
import path from "path";

export async function findUp(dir: string, fn: (dir: string) => Promise<string | undefined>): Promise<string | undefined> {
	const current = path.resolve(dir);
	const s = await fn(current);
	if(s !== undefined)
		return s;
	const parent = path.dirname(current);
	if(parent === current)
		return undefined;
	return findUp(parent, fn);
}

type fsPromises = typeof promises;

export async function getProjectDir(fs: fsPromises): Promise<string> {
	return findUp(__dirname, async dir => {
		const file = path.join(dir, "package.json");
		const s = await stat(fs, file);
		if(s && s.isFile())
			return dir;
		return undefined;
	});
}

export async function stat(fs: fsPromises, file: string): Promise<Stats | undefined> {
	try {
		return await fs.lstat(file);
	} catch {
		return undefined;
	}
}

export function combine(dir: string, target: string): string {
	if(path.isAbsolute(target))
		return target;
	const s = path.join(dir, target);
	return path.normalize(s);
}

export function combineAsUrl(base: string, target: string): string {
	const dir = base.endsWith("/") ? base : path.dirname(base);
	const urlPath = combine(dir, target);
	if(isIndex(urlPath))
		return path.dirname(urlPath) + "/";
	return urlPath;
}

function isIndex(s: string): boolean {
	const f = path.basename(s);
	return f === "index.html";
}

export async function walk(fs: fsPromises, dir: string, fn: (f: string) => void, recursive: boolean): Promise<void> {
	const d = await fs.opendir(dir);
	for await (const e of d){
		const f = path.join(dir, e.name);
		if(e.isDirectory()){
			if(recursive)
				await walk(fs, f, fn, recursive);
			continue;
		}
		await fn(f);
	}
}
