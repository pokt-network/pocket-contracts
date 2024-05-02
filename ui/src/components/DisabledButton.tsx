type DisabledButtonProps = {
  text: string;
};

export const DisabledButton = ({
  text,
}: DisabledButtonProps) => {
  
  return (
    <button
      disabled={true}
      className="inline-flex items-center justify-center center py-3 px-4 text-lg font-bold whitespace-nowrap rounded px-2 py-1 font-semibold text-white shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-500 cursor-not-allowed bg-gray-400"
    >
      {text}
    </button>
  );
};
