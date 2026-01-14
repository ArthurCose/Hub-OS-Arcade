const fs = require("fs");

const PRIZE_PREVIEW_PATH = "assets/prize_previews";

try {
  fs.mkdirSync(PRIZE_PREVIEW_PATH);
} catch {}

function indexAfter(string, search, position) {
  const index = string.indexOf(search, position);

  if (index == -1) {
    return -1;
  }

  return index + search.length;
}

function patchFrame(frameContents, offsetX, offsetY) {
  // shift origin to center within the mug
  const originxStartIndex = indexAfter(frameContents, "originx=");
  const originyStartIndex = indexAfter(frameContents, "originy=");
  const originxEndIndex = frameContents.indexOf(" ", originxStartIndex);
  const originyEndIndex = frameContents.indexOf(" ", originyStartIndex);

  let originx = parseFloat(
    frameContents.slice(originxStartIndex, originxEndIndex)
  );
  let originy = parseFloat(
    frameContents.slice(originyStartIndex, originyEndIndex)
  );

  originx -= offsetX;
  originy -= offsetY;

  // patch anim contents, we're assuming originx appears first
  return (
    frameContents.slice(0, originxStartIndex) +
    originx +
    frameContents.slice(originxEndIndex, originyStartIndex) +
    originy +
    frameContents.slice(originyEndIndex)
  );
}

let contents = fs.readFileSync("assets/bots/prizes.animation", "utf8");
let nextStart = 0;

while (nextStart != -1) {
  const startIndex = nextStart;
  nextStart = contents.indexOf("anim ", nextStart + 1);

  const endIndex = nextStart == -1 ? contents.length : nextStart;

  let animContents = contents.slice(startIndex, endIndex);

  const stateStartIndex = 5;
  const stateEndIndex = animContents.indexOf("\n");
  const stateName = animContents.slice(stateStartIndex, stateEndIndex);

  if (stateName == "DEFAULT" || stateName.endsWith("_MIRRORED")) {
    continue;
  }

  const framesContents = animContents.slice(stateEndIndex);

  // replace state name with IDLE
  animContents = animContents.slice(0, stateStartIndex) + "IDLE";

  // resolve offset
  let offsetX = 20;
  let offsetY = 40;

  if (stateName.startsWith("Swordy")) {
    offsetX -= 4;
  } else if (stateName.startsWith("Spikey")) {
    offsetX -= 1;
  } else {
    offsetX -= 2;
  }

  // patch frames
  let nextFrameStartIndex = 1;

  while (nextFrameStartIndex != -1) {
    const frameStartIndex = nextFrameStartIndex;
    nextFrameStartIndex = framesContents.indexOf(
      "frame ",
      nextFrameStartIndex + 1
    );

    let frameEndIndex = framesContents.indexOf("\n", frameStartIndex);

    if (frameEndIndex == -1) {
      frameEndIndex = framesContents.length;
    }

    const frameContents = framesContents.slice(frameStartIndex, frameEndIndex);
    animContents += "\n" + patchFrame(frameContents, offsetX, offsetY);
  }

  animContents += "\n";

  fs.writeFileSync(
    `${PRIZE_PREVIEW_PATH}/${stateName}.animation`,
    animContents
  );
}
