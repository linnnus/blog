for (const anchor of document.querySelectorAll("main a[href^=http]")) {
	const image = document.createElement("img");
	const { hostname } = new URL(anchor.href);
	image.src = `https://www.google.com/s2/favicons?domain=${hostname}&sz=32`;
	image.classList.add("favicon");
	anchor.insertAdjacentElement("beforeend", image);
}
